# Copyright(c) 2025 NVIDIA Corporation. All rights reserved.

# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

from loguru import logger
from uuid import uuid4
import json
import ast
import base64
import os
import yaml
from pathlib import Path
from dataclasses import dataclass

from pipecat.processors.frame_processor import FrameProcessor, FrameDirection
from pipecat.frames.frames import Frame
from nvidia_pipecat.frames.custom_view import (
    StartCustomViewFrame,
    StopCustomViewFrame,
    Block,
    TableBlock,
    ImageBlock,
    Image,
)
from nvidia_pipecat.frames.nvidia_rag import NvidiaRAGCitation, NvidiaRAGCitationsFrame
from .config import Config

# Default configuration value
DEFAULT_CONFIDENCE_THRESHOLD = 0.5

try:
    config_path = os.getenv("CONFIG_PATH", "configs/config.yaml")
    logger.info(f"Attempting to load config from: {config_path}")
    config_data = yaml.safe_load(Path(config_path).read_text())
    config = Config(**config_data)
    logger.info(f"Successfully loaded config with threshold: {config.CustomViewProcessor.confidence_threshold}")
except Exception as e:
    logger.warning(f"Failed to load config from {config_path}: {e}. Using default values.")
    # Create a simple config object with just the needed attribute
    config = type('SimpleConfig', (), {})()
    config.CustomViewProcessor = type('CustomViewProcessorConfig', (), {'confidence_threshold': DEFAULT_CONFIDENCE_THRESHOLD})()
    logger.info(f"Using default confidence threshold: {DEFAULT_CONFIDENCE_THRESHOLD}")

class CustomViewProcessor(FrameProcessor):
    """Processes RAG citations and transforms them into UI-renderable custom view components.
    
    This processor transforms NvidiaRAGCitationsFrame frames into UI-friendly 
    StartCustomViewFrame frames. It filters citations based on confidence thresholds
    and displays images, tables, and charts.
    
    Input frames:
    - NvidiaRAGCitationsFrame (consumed): Contains RAG citations with document data and scores.
    
    Output frames:
    - StartCustomViewFrame: Contains UI-renderable blocks created from citations.
    - StopCustomViewFrame: Sent when there are no relevant citations.
    """

    def __init__(self):
        """Initialize the processor with confidence threshold configuration."""
        super().__init__()
        self.confidence_threshold = config.CustomViewProcessor.confidence_threshold
        self.top_n = config.CustomViewProcessor.top_n
        logger.info(
            f"Initialized CustomViewProcessor with confidence threshold: {self.confidence_threshold}, "
            f"max citations: {self.top_n}"
        )

    async def process_frame(self, frame: Frame, direction: FrameDirection) -> None:
        await super().process_frame(frame, direction)
        
        if not isinstance(frame, NvidiaRAGCitationsFrame):
            await super().push_frame(frame, direction)
            return
        
        logger.info("Processing NvidiaRAGCitationsFrame")
        blocks = []
        
        if not frame.citations:
            await self.push_frame(StopCustomViewFrame(action_id="custom-view"), direction)
            return

        # Filter by confidence threshold and document type
        relevant_citations = [
            c for c in frame.citations 
            if c.score >= self.confidence_threshold and c.document_type in ["table", "chart", "image"]
        ]
        
        # Sort by score and take top N
        top_citations = sorted(relevant_citations, key=lambda c: c.score, reverse=True)[:self.top_n]

        logger.info(
            f"Citation filtering results: "
            f"Total: {len(frame.citations)}, "
            f"Valid visual elements: {len(relevant_citations)} (confidence >= {self.confidence_threshold}), "
            f"Selected: {len(top_citations)} (limit: {self.top_n})"
        )

        # Process the top citations
        for citation in top_citations:
            try:
                # Parse metadata safely
                metadata = self._parse_metadata_safely(citation.metadata)
                
                # Process charts and images
                if citation.document_type in ["chart", "image"]:
                    success = self._process_image_citation(citation, blocks)
                    if not success:
                        logger.warning(f"Failed to process chart/image citation {citation.document_id}")
                        
                elif citation.document_type == "table":
                    # First try to process as table
                    success = self._process_table_citation(citation, blocks, metadata)
                    if not success and citation.content:
                        # Fall back to image display if we have content
                        logger.info(f"Table processing failed for {citation.document_id}, falling back to image display")
                        success = self._process_image_citation(citation, blocks)
                        if not success:
                            logger.warning(f"Failed to process table citation {citation.document_id} as table or image")
                else:
                    logger.warning(f"Unknown document type: {citation.document_type}")
            except Exception as e:
                logger.error(f"Failed to process citation {citation.document_id}: {e}")
                import traceback
                logger.error(f"Traceback: {traceback.format_exc()}")
                continue

        # If no blocks were created, send StopCustomViewFrame
        if not blocks:
            logger.info("No blocks created from citations, sending StopCustomViewFrame")
            await self.push_frame(StopCustomViewFrame(action_id="custom-view"), direction)
            return
            
        await self.push_frame(StartCustomViewFrame(blocks=blocks), direction)

    def _process_image_citation(self, citation: NvidiaRAGCitation, blocks: list[Block]) -> bool:
        """Process a citation that should be displayed as an image."""
        if not citation.content:
            return False
            
        try:
            is_base64_image, content_str = self._is_base64_image(citation.content)
            
            if is_base64_image:
                image_data = content_str
            else:
                image_data = base64.b64encode(citation.content).decode('utf-8')
            
            blocks.append(ImageBlock(
                id=str(uuid4()),
                image=Image(data=image_data),
                caption=citation.document_name
            ))
            return True
        except Exception as e:
            logger.error(f"Failed to process image data: {e}")
            return False

    def _parse_metadata_safely(self, metadata_str):
        """Safely parse metadata string that might be in Python dict format or JSON."""
        if not metadata_str:
            return {}
            
        try:
            # Try parsing as Python literal (handles single quotes)
            return ast.literal_eval(metadata_str)
        except (SyntaxError, ValueError):
            try:
                # Try parsing as JSON (handles double quotes)
                return json.loads(metadata_str)
            except json.JSONDecodeError:
                return {}

    def _process_table_citation(self, citation: NvidiaRAGCitation, blocks: list[Block], metadata=None) -> bool:
        """Process a table citation and create a TableBlock.
        
        Extracts table content from metadata, processes it by:
        1. First row is treated as title (for logging only)
        2. Second row is used as header row
        3. Remaining rows are used as data rows
        
        Tables formatted with |n notation are handled by converting to newlines.
        """
        try:
            if metadata is None:
                metadata = self._parse_metadata_safely(citation.metadata)

            table_content = metadata.get("description", "")
            
            if not table_content:
                logger.warning(f"Empty table content for citation {citation.document_id}")
                return False

            # Print raw content for debugging
            logger.debug(f"Raw table content: {repr(table_content)}")
            
            # Handle |n notation by replacing it with actual newlines
            if "|n" in table_content:
                table_content = table_content.replace("|n", "\n")
                logger.debug(f"Replaced |n with newlines in table for {citation.document_id}")
            
            # Split by newline to get rows
            rows = table_content.splitlines()
            logger.debug(f"Found {len(rows)} rows after splitting by newlines")

            # Process each row
            valid_rows = []
            for row_idx, row_str in enumerate(rows):
                row_str = row_str.strip()
                
                # If we have a pipe at the start but not at the end, add it
                if row_str and row_str.startswith('|') and not row_str.endswith('|'):
                    row_str += '|'
                    
                if row_str and row_str.startswith('|') and row_str.endswith('|'):
                    # Split by '|' and remove empty strings from start/end
                    cells = [cell.strip() for cell in row_str.split('|')[1:-1]]
                    if cells and any(cell.strip() for cell in cells):  # At least one non-empty cell
                        valid_rows.append(cells)
                    elif cells:  # Keep non-separator rows (rows that are not just |---|---|)
                        if not all(c == '-'*len(c) for c in cells if c):
                            valid_rows.append(cells)
                else:
                    logger.debug(f"Row {row_idx}: Skipping invalid format row: {row_str}")

            logger.debug(f"Found {len(valid_rows)} valid rows for citation {citation.document_id}")

            if len(valid_rows) < 2:  # Need at least header and one data row
                logger.warning(f"Not enough valid rows ({len(valid_rows)}) found for citation {citation.document_id}")
                return False

            # Extract title, header and data rows
            title_row = valid_rows[0] if valid_rows else []
            header_row = valid_rows[1] if len(valid_rows) > 1 else []
            raw_data_rows = valid_rows[2:] if len(valid_rows) > 2 else []

            # Extract title for logging only
            table_title = title_row[0] if title_row and len(title_row) > 0 else citation.document_name
            num_headers = len(header_row)

            if num_headers == 0:
                logger.warning(f"No headers found in table citation {citation.document_id}")
                return False

            # Check if all data rows have the correct number of cells
            # If any row has a different number of cells than the header,
            # consider this an invalid table and return False
            for i, row in enumerate(raw_data_rows):
                if len(row) != num_headers:
                    logger.warning(
                        f"Row {i} has {len(row)} cells, which doesn't match header count ({num_headers}). "
                        f"Falling back to image rendering for table {citation.document_id}"
                    )
                    return False

            # All rows have the correct number of cells, no normalization needed
            if not raw_data_rows:
                logger.warning(f"No valid data rows found for citation {citation.document_id}")
                return False

            # Create TableBlock
            blocks.append(TableBlock(
                id=str(uuid4()),
                headers=header_row,
                rows=raw_data_rows
            ))

            logger.info(
                f"Successfully processed table '{table_title}' with "
                f"{len(raw_data_rows)} rows and {len(header_row)} columns"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to process table citation {citation.document_id}: {e}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
            return False

    def _is_base64_image(self, content):
        """Check if content is a base64-encoded image."""
        if not content:
            return False, ""
        
        try:
            content_str = content.decode('utf-8', errors='ignore')
            is_base64_image = (
                content_str.startswith("iVBOR") or  # PNG
                content_str.startswith("/9j/") or   # JPEG
                content_str.startswith("R0lGOD")    # GIF
            )
            return is_base64_image, content_str
        except:
            return False, ""

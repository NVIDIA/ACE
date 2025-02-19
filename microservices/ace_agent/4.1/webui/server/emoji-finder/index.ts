/*
 * SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import * as fs from "fs";
import "@tensorflow/tfjs";
import * as use from "@tensorflow-models/universal-sentence-encoder";
import { Tensor2D } from "@tensorflow/tfjs";
import * as tf from "@tensorflow/tfjs-core";
import * as path from "path";

interface Emoji {
  emoji: string;
  description: string;
  tags: string[];
  aliases: string[];
}

/**
 * Finds the emoji that best matches an arbitrary text string, using tensorflow's
 * universal string encoder.
 *
 * Usage:
 * ```
 * const emojiFinder = EmojiFinder.fromEmojiFile("./emojis/all.json")
 * await emojiFinder.init()
 * await emojiFinder.findEmoji("Dance moves") // 🕺
 * ```
 */
export default class EmojiFinder {
  private emojis: Emoji[] = [];
  private model: use.UniversalSentenceEncoder;

  /**
   * Emojis represented as 2D embeddings
   */
  private emojisEmbeddings: Tensor2D;

  /**
   * Computing embeddings can take a while, which is inconvenient in
   * situations where the application is relaunched frequently (e.g.
   * hot-reloading in development mode). For faster load times, the
   * embeddings are cached on the disk.
   */
  private static readonly cachedEmbeddingsPath: string = path.join(
    import.meta.dirname,
    "./cached-emoji-embeddings.json"
  );

  constructor(emojis: Emoji[]) {
    this.emojis = emojis;
  }

  /**
   * Initializes the instance by loading tensorflow's universal string encoder, and using it
   * to convert the emojis to embeddings
   */
  public async init(): Promise<EmojiFinder> {
    this.model = await use.load();
    this.emojisEmbeddings = await this.createEmbeddings();
    return this;
  }

  /**
   * Finds the closest matching emojis for a given string. The string is converted into
   * an embedding, which is compared against the list of emoji embeddings. The emojis
   * matching the closest embedding is returned
   */
  public async findEmoji(text: string): Promise<Emoji> {
    if (!this.emojisEmbeddings) {
      throw new Error(
        "Tried to find emojis but no embeddings were found. Did you call init()?"
      );
    }
    const sampleEmbedding = await this.model.embed([text.toLowerCase()]);

    let maxScore = 0,
      maxIndex = 0;
    for (let j = 0; j < this.emojis.length; j++) {
      const emojiEmbedding = tf.slice(this.emojisEmbeddings, [j, 0], [1]);
      const score = tf
        .matMul(sampleEmbedding, emojiEmbedding, false, true)
        .dataSync();

      if (score[0] > maxScore) {
        maxScore = score[0];
        maxIndex = j;
      }
    }
    return this.emojis[maxIndex];
  }

  /**
   * Creates a new instance of EmojiFinder by reading the list of emojis using the provided
   * path
   *
   * @param path Path to a JSON file containing emojis. The file should contain an array
   * of emojis, where each emoji is represented as:
   * {
   *   "emoji": "<emoji>",
   *   "description": "<description>",
   *   "tags": ["<tag 1>", "<tag 2>", ...]
   * }
   *
   * Good emoji descriptions make the finder more accurate.
   */
  public static fromEmojiFile(path: string): EmojiFinder {
    const fileContent = EmojiFinder.readFile(path);
    const emojis = EmojiFinder.parseJSON(fileContent.toString());
    EmojiFinder.validateEmojis(emojis);

    return new EmojiFinder(emojis);
  }

  /**
   * Creates 2D embeddings from the instance's emojis. The embeddings are cached
   * on the disk for faster hot-reloads
   * @returns
   */
  private async createEmbeddings(): Promise<Tensor2D> {
    const cachedEmbeddings = this.loadEmbeddingsFromCache();
    if (cachedEmbeddings) {
      return cachedEmbeddings;
    }

    if (!this.emojis.length) {
      throw new Error(
        "Tried to create embeddings for emojis but no emojis were set. Did you call init()?"
      );
    }
    const embeddings = await this.model.embed(
      this.emojis.map((emoji) =>
        `${emoji.description} ${emoji.tags.join(" ")} ${emoji.aliases.join(
          " "
        )}`.toLowerCase()
      )
    );

    this.storeEmbeddingsToCache(embeddings);

    return embeddings;
  }

  /**
   * Tries to load embeddings from cache, on the disk. Returns
   * The embeddings if the number of cached embeddings matches the
   * number of emojis. If the length is different, assumes the cache
   * is no longer valid, and returns nothing
   * @returns the cached emojis, if available
   */
  private loadEmbeddingsFromCache(): Tensor2D | null {
    try {
      const cachedEmbeddings = EmojiFinder.readFile(
        EmojiFinder.cachedEmbeddingsPath
      );
      const parsed = JSON.parse(cachedEmbeddings.toString());
      if (parsed.length === this.emojis.length) {
        return tf.tensor(parsed);
      }
    } catch (e) {
      return null;
    }
  }

  /**
   * Writes embeddings to cache, on the disk
   * @param embeddings
   */
  private storeEmbeddingsToCache(embeddings: Tensor2D): void {
    const data = embeddings.arraySync();
    fs.writeFileSync(
      EmojiFinder.cachedEmbeddingsPath,
      JSON.stringify(data),
      "utf8"
    );
  }

  /**
   * Reads the file at the provided path
   */
  private static readFile(path: string): Buffer {
    return fs.readFileSync(path);
  }

  /**
   * Parses a JSON string to an untyped JavaScript object
   */
  private static parseJSON(jsonString: string): unknown {
    return JSON.parse(jsonString);
  }

  /**
   * Ensures a list of objects is a list of emojis. If any emoji is not valid, throws
   * an error
   */
  private static validateEmojis(emojis: unknown): asserts emojis is Emoji[] {
    if (!Array.isArray(emojis)) {
      throw new Error(
        `Object is not a valid list of emojis (expected an Array, got ${typeof emojis} instead`
      );
    }

    emojis.forEach((emoji) => EmojiFinder.validateEmoji(emoji));
  }

  /**
   * Ensures an emoji is a valid shape of emoji. If it's not, this function throws
   * with an error
   * @param emoji the object to cast
   */
  private static validateEmoji(emoji: unknown): asserts emoji is Emoji {
    if (typeof emoji !== "object") {
      throw new Error(
        `Object ${emoji} is not a valid emoji (expect object, got ${typeof emoji} instead)`
      );
    }
    if (!("emoji" in emoji) || typeof emoji.emoji !== "string") {
      throw new Error(
        `Object ${emoji} is not a valid emoji (missing property 'emoji' of type string)`
      );
    }
    if (!("description" in emoji) || typeof emoji.description !== "string") {
      throw new Error(
        `Object ${emoji} is not a valid emoji (missing property 'description' of type string)`
      );
    }
    if (
      !("tags" in emoji) ||
      !Array.isArray(emoji.tags) ||
      !emoji.tags.every((tag) => typeof tag === "string")
    ) {
      throw new Error(
        `Object ${emoji} is not a valid emoji (missing property 'tags' of type string[])`
      );
    }
    if (
      !("aliases" in emoji) ||
      !Array.isArray(emoji.aliases) ||
      !emoji.aliases.every((tag) => typeof tag === "string")
    ) {
      throw new Error(
        `Object ${emoji} is not a valid emoji (missing property 'aliases' of type string[])`
      );
    }
  }
}

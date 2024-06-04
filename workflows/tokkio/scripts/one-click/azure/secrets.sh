#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

# _azure_app_reg_client_secret -> client secret value of the azure app registration with access to the resources
export _azure_app_reg_client_secret='<replace_content_between_quotes_with_your_value>'
# _ssh_public_key -> Your public ssh key's content
export _ssh_public_key='<replace_content_between_quotes_with_your_value>'
# _ngc_api_key -> Your ngc api key value
export _ngc_api_key='<replace_content_between_quotes_with_your_value>'
# _turnserver_password -> Password for turn server
export _coturn_password='<replace_content_between_quotes_with_your_value>'
# Set the open ai API key 
export _openai_api_key='<replace_content_between_quotes_with_your_value>'

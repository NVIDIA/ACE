#!/usr/bin/env node

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

const fs = require('fs');
const { execFileSync } = require('child_process');


// We use the env.js file to populate environment variables that are only available at
// startup time. In practice, this is the case for the server's port number, which is
// available in the VITE_SERVER_PORT environment variable. We write this environment
// variable to the env.js file so that the client can access it.
try {

    const VITE_SERVER_PORT = process.env.VITE_SERVER_PORT ? parseInt(process.env.VITE_SERVER_PORT, 10) : undefined;

    const content = `window.process = window.process ? window.process : {};
    window.process.env = window.process.env ? window.process.env : {};
    
    window.process.env.VITE_SERVER_PORT = ${JSON.stringify(VITE_SERVER_PORT)};`;

    fs.writeFileSync('/app/client/dist/env.js', content);
    console.log('env.js file has been created successfully.');
} catch (err) {
    console.error('Error writing to file:', err);
    process.exit(1);
}

// Serve the web client statically
try {
    console.log('Starting http-server...');
    const args = process.argv.slice(2);
    execFileSync('node', ['../node_modules/http-server/bin/http-server', '-p', '7006', ...args], { stdio: 'inherit' });
} catch (error) {
    console.error('Error starting http-server:', error);
    process.exit(1);
}
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

import { describe, it, before } from "node:test";
import * as assert from "node:assert";
import EmojiFinder from ".";

const emojis = [
  {
    emoji: "🕺",
    description: "man dancing",
    aliases: ["man_dancing"],
    tags: ["dancer"],
  },
  {
    emoji: "🍵",
    description: "teacup without handle",
    aliases: ["tea"],
    tags: ["green", "breakfast"],
  },
  {
    emoji: "😃",
    description: "grinning face with big eyes",
    aliases: ["smiley"],
    tags: ["happy", "joy", "haha"],
  },
];

describe("EmojiFinder", () => {
  let emojiFinder: EmojiFinder;
  before(async () => {
    emojiFinder = new EmojiFinder(emojis);
    await emojiFinder.init();
  });

  it("Finds an appropriate emoji for various texts", async () => {
    const [danceEmoji, happyEmoji, teaEmoji] = await Promise.all([
      emojiFinder.findEmoji("Dance moves"),
      emojiFinder.findEmoji("Happiness"),
      emojiFinder.findEmoji("A cup of tea"),
    ]);
    assert.strictEqual(danceEmoji.emoji, "🕺");
    assert.strictEqual(happyEmoji.emoji, "😃");
    assert.strictEqual(teaEmoji.emoji, "🍵");
  });
});

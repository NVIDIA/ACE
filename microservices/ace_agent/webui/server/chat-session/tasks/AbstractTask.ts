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

import { EventEmitter } from "node:events";
import { InteractionMode } from "../../../shared/types.js";

/**
 * This is the base class that all "tasks" running on the server must extend. A task is a
 * unit responsible for managing a specific aspect of the web application (e.g. speech),
 * and how the feature communicates with the APIs (e.g. gRPC).
 */
export default abstract class AbstractTask {
  /**
   * What interaction modes are supported by the task (speech, text or both).
   */
  public abstract readonly interactionModes: InteractionMode[];

  /**
   * All tasks must subscribe to the abort controller when they start running. When the
   * abort controller is triggered, a task must stop its execution.
   */
  protected abortController: AbortController;

  /**
   * Constructor for the task
   * @param eventBus an object on which tasks can subscribe and publish events. The event
   * bus is shared across all tasks belonging to a user's session. This allows tasks
   * to communicate with each other.
   */
  constructor(protected readonly eventBus: EventEmitter) {}

  /**
   * The core logic of the task. A task may be stopped and started multiple times. Tasks
   * must override this method with specific logic, and call super.start(). Their logic
   * must stop when the abortController is called.
   */
  public start() {
    this.abortController = new AbortController();
  }

  /**
   * Stops the task. A task may be stopped and started multiple times for a user's
   * session. Subclasses generally do not need to override this method. To detect when the
   * task is stopped, subclasses should instead subscribe to the class' abortController.
   */
  public stop() {
    if (this.abortController) {
      this.abortController.abort();
    }
  }

  /**
   * To check whether the task is currently running.
   * @returns true if the task is currently running, false otherwise
   */
  public isRunning(): boolean {
    if (!this.abortController) {
      return false;
    }
    return !this.abortController.signal.aborted;
  }

  /**
   * For async logic that must run after the task has stopped. This is called once, after
   * the task is stopped. After cleanup, the task is guaranteed not to start again. By
   * default, this function does nothing. The subclasses may add specific logic by
   * overriding this method.
   */
  public async cleanup() {}
}

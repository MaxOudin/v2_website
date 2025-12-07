// Import and register all your controllers
import { application } from "./application"

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import MistralTranslatorController from "./mistral_translator_controller"
application.register("mistral-translator", MistralTranslatorController)
// Import and register all your controllers from the importmap via controllers/**/*_controller
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
application.debug = true
window.Stimulus = application

eagerLoadControllersFrom("controllers", application)

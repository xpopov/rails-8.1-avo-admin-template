import { application } from "./application"

const controllers = import.meta.glob("./**/*_controller.js", { eager: true })

for (const [path, module] of Object.entries(controllers)) {
  const identifier = path.replace(/^\.\//, "").replace(/_controller\.js$/, "").replace(/\//g, "--").replace(/_/g, "-")
  application.register(identifier, module.default)
}

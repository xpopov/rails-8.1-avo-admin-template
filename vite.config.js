import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"
import FullReload from "vite-plugin-full-reload"
import StimulusHMR from "vite-plugin-stimulus-hmr"

export default defineConfig({
  build: { sourcemap: false },
  plugins: [
    RubyPlugin(),
    StimulusHMR(),
    FullReload(["app/views/**/*", "app/helpers/**/*.rb", "config/routes.rb"]),
  ],
})

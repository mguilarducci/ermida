import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    tailwindcss(),
  ],
  server: {
    // In Docker, Rails proxies asset requests with Host "vite" (the compose service)
    allowedHosts: ['vite'],
  },
})

import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-inter)", "ui-sans-serif", "system-ui", "sans-serif"]
      },
      colors: {
        brand: {
          bg: "#f8fafc",
          text: "#1e293b",
          accent: "#0d9488"
        }
      }
    }
  },
  plugins: []
};

export default config;

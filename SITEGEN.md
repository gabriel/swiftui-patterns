# 🧭 Documentation site

The documentation site now runs on [VitePress](https://vitepress.dev/) so you get fast hot-module reload, a modern theme, and polished typography out of the box.

```sh
npm install
npm run docs:dev     # local dev server
npm run docs:build   # static build -> docs/.vitepress/dist
```

Deploy the built output to GitHub Pages (or any static host) using the `docs/.vitepress/dist` folder. The site is already configured with the `/swiftui-patterns/` base path so it works with `username.github.io/swiftui-patterns`.

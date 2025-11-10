import { defineConfig } from 'vitepress'

export default defineConfig({
  lang: 'en-US',
  title: 'SwiftUI Patterns',
  description: 'A collection of SwiftUI patterns, best practices, and architectural approaches for building modern iOS applications.',
  base: '/swiftui-patterns/',
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    siteTitle: 'SwiftUI Patterns',
    logo: {
      src: '/logo.svg',
      alt: 'SwiftUI Patterns'
    },
    nav: [
      {
        text: 'Patterns',
        items: [
          { text: 'Navigation', link: '/navigation/' },
          { text: 'UI', link: '/ui/' },
          { text: 'Dependencies', link: '/dependencies/' },
          { text: 'Testing', link: '/testing/' },
          { text: 'Awesome Libraries', link: '/awesome/' }
        ]
      }
    ],
    sidebar: [
      {
        text: 'Navigation',
        collapsed: false,
        items: [
          { text: 'Overview', link: '/navigation/' },
          { text: 'SwiftUI Routes', link: '/navigation/swiftui-routes' }
        ]
      },
      {
        text: 'UI',
        collapsed: false,
        items: [
          { text: 'Overview', link: '/ui/' },
          { text: 'ScrollViewport', link: '/ui/ScrollViewport' },
          { text: 'HipsterLorem', link: '/ui/HipsterLorem' }
        ]
      },
      {
        text: 'Dependencies',
        collapsed: false,
        items: [
          { text: 'Overview', link: '/dependencies/' },
          { text: 'Dependencies (Point-Free)', link: '/dependencies/dependencies' },
          { text: 'Dependencies (Micro App)', link: '/dependencies/micro' },
          { text: 'FactoryKit', link: '/dependencies/factory' }
        ]
      },
      {
        text: 'Testing',
        collapsed: false,
        items: [
          { text: 'Overview', link: '/testing/' },
          { text: 'SwiftUI Snapshots', link: '/testing/swiftui-snapshots' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/gabriel/swiftui-patterns' }
    ],
    footer: {
      message: 'MIT Licensed',
      copyright: '© ' + new Date().getFullYear() + ' Gabriel Handford'
    },
    search: {
      provider: 'local'
    }
  }
})

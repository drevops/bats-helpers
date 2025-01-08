// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// @see https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'BATS Helpers',
  tagline: 'Helpers and assertions for BATS testing',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://bats-helpers.drevops.com/',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  organizationName: 'drevops',
  projectName: 'bats-helpers',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
          path: 'content',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl: 'https://github.com/drevops/bats-helpers/tree/main/docs/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
        gtag: {
          trackingID: 'G-CMCFVS7NMX',
          anonymizeIP: true,
        },
      }),
    ],
  ],

  markdown: {
    mermaid: true,
  },

  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      /** @type {import("@easyops-cn/docusaurus-search-local").PluginOptions} */
      ({
        // @see https://github.com/easyops-cn/docusaurus-search-local#theme-options
        searchBarPosition: 'left',
        docsRouteBasePath: '/',
        indexBlog: false,
        hashed: true,
        highlightSearchTermsOnTargetPage: true,
        explicitSearchResultPath: true,
      }),
    ],
    '@docusaurus/theme-mermaid',
  ],

  themeConfig:
  /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      image: 'img/social-card.jpg',
      navbar: {
        logo: {
          alt: 'BATS Helpers Logo',
          src: 'img/logo.png',
        },
        items: [
          {
            label: 'Download',
            href: 'https://github.com/drevops/bats-helpers/releases/latest',
            position: 'right',
            title: 'Download the latest version',
          },
          {
            href: 'https://github.com/drevops/bats-helpers',
            label: 'GitHub',
            position: 'right',
            title: 'View source on GitHub',
          },
          {
            type: 'search',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            label: 'GitHub',
            href: 'https://github.com/drevops/bats-helpers',
          },
        ],
        copyright: `Copyright ©${new Date().getFullYear()} DrevOps. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['php', 'bash'],
      },
      colorMode: {
        defaultMode: 'light',
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },
    }),
};

export default config;

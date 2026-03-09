# WorkOS x Okta SSO Portal Demo

> WorkOS SSO & DirectorySync demo using Okta as the IdP, built with Rails 8.

This Rails app is a demo of using the Standalone SSO and DirectorySync APIs from WorkOS, built using the [WorkOS Ruby SDK](https://github.com/workos/workos-ruby).

Made with:

- Rails 8.1.2
- [WorkOS Ruby SDK](https://github.com/workos/workos-ruby) version `6.1.0`
- [Tailwind CSS](https://tailwindcss.com/) for light styling, via the [`tailwindcss-rails` gem](https://github.com/rails/tailwindcss-rails)
- [Radix icon](https://www.radix-ui.com/icons) support via the [rails_icons gem](https://github.com/rails-designer/rails_icons)
- Love! 💖

For more information on how this was built, see [Design Decisions & Tradeoffs](#design-decisions--tradeoffs).

## Demo Screencast

## Getting Started in Development

Given the opinionated nature of this demo, running this app makes a few assumptions, which are outlined in the [Pre-launch setup](#pre-launch-setup).

### Pre-launch setup

To run the app locally, you'll need:

- A machine with Ruby 3.4.7+ and sqlite3 installed. You can check this with the following commands in Terminal:

```shell
ruby --version 
> ruby 3.4.7 (2025-10-08 revision 7a5688e2a2) +PRISM [arm64-darwin25]

command -v sqlite3 # so we can check install without running sqlite3
> /usr/bin/sqlite3
```

- A [WorkOS account](https://workos.com/signup) and an [Okta Developer account](https://developer.okta.com/signup/) on (at minimum) the Integrator Free plan, along with:
  - An Okta organization with a few users you can assign to a Directory
  - An [Okta Connection configured with SAML](https://workos.com/docs/integrations/okta-saml)
  - An [Okta SCIM integration](https://workos.com/docs/integrations/okta-scim)

  The above will provide us with the credentials we need to get running, namely:

  - `WORKOS_CLIENT_ID` & `WORKOS_API_KEY`, which you can find in your [WorkOS Dashboard](https://dashboard.workos.com/get-started)
  - your Organization ID (`WORKOS_ORGANIZATION_ID`), which you can find in your [WorkOS Dashboard](https://dashboard.workos.com/) under **Organizations > Organization details** for your Okta-connected organization. This ID will be prefixed with `org_`
  - A Redirect URI, as configured in the **Redirects** settings of your [WorkOS Dashboard](https://dashboard.workos.com/); for local development, `http://localhost:3000/auth/callback` is sufficient.

## Get running

1. Clone this repo:

   `git clone https://github.com/alidacodes/workos_rails_demo.git && cd workos_rails_demo`

2. From here, you have two options: Pre-configure your `.env` or configure interactively during first launch.
   1. **Preconfigure your env.**
      - Copy the `.env.example` as `.env`:

         `cp .env.example .env`

      - Replace the default values for `WORKOS_API_KEY`, `WORKOS_CLIENT_ID`, and `WORKOS_ORGANIZATION_ID` with your credentials. Replace the `WORKOS_REDIRECT_URI` with `http://localhost:3000/auth/callback` for local development.

        > The `.env` file is in the project's `.gitignore` by default, but please, **never commit your `.env` file or sensitive credentials.** 😊

      - In the project's root directory (`workos_rails_demo/`), you can start the app via CLI with:

        `bin/start --dev`

      - Open the app at `http://localhost:3000` and explore!

   2. **Interactive configuration**
      - In the project's root directory (`workos_rails_demo/`), you can start the app via CLI with:

        `bin/start --dev`

      - The startup script will prompt you for each of the four required credentials in the terminal, which it will then store in a `.env` file. For `WORKOS_REDIRECT_URI`, you may use `http://localhost:3000/auth/callback` for local development

        > The `.env` file is in the project's `.gitignore` by default, but please, **never commit your `.env` file or sensitive credentials.** 😊

      - Open the app at `http://localhost:3000` and explore!

## Design Decisions & Tradeoffs

See [docs/design_decisions.md](docs/design_decisions.md)

# Seting up InertiaJS with Phoenix

## Initial Setup

First, we create a new Phoenix project. For simplicity, I created this repo with the `--no-ecto` flag to skip a database, since Inertia just deals with rendering. The project is called 'momentum' to be a bit cheeky.

The code for this repo is available at [https://github.com/joseph-lozano/inertia-phoenix-example](https://github.com/joseph-lozano/inertia-phoenix-example).

Each subheading corresponds to a commit in the repo, so you can easily see changes made during the project.


## Setting up Inertia with Client Side Rendering

### Changes to Phoenix server

First, add `:inertia` to your list of dependencies in `mix.exs`. The current version (as of writing) is `0.7.0`.

```elixir
# mix.exs
def deps do
  [
    # ... previous deps
    {:inertia, "~> 0.7.0"}
  ]
end
```

Next, add the Inertia config to `config/config.exs`. We are going to leave `ssr: false` for now.
```elixir
# config/config.exs

config :inertia,
  endpoint: MomentumWeb.Endpoint,
  ssr: false
```

Next, in your app's `_web.ex` file, add imports for Inertia.Controller, and Inertia.HTML
```elixir
# lib/momentum_web.ex
defmodule MomentumWeb do

  # ... other helpers

   def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: MomentumWeb.Layouts]

      import Plug.Conn
      import MomentumWeb.Gettext
      import Inertia.Controller # <-- Add this line

      unquote(verified_routes())
    end
  end

  # ... other helpers

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]
      import Inertia.HTML # <-- Add this line


      unquote(html_helpers())
    end
  end

  #... other helpers

end


In your router file, add the Inertia plug to the pipeline

```elixir
# lib/momentum_web/router.ex
defmodule MomentumWeb.Router do
  use MomentumWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MomentumWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Inertia.Plug # <-- Add this line
  end

  # ... rest of the router
end
```

If your root html file, swap out the `<.live_title>` component with inertia's head component

```diff
# lib/momentum_web/templates/layout/root.html.heex
<!DOCTYPE html>
<html lang="en" class="[scrollbar-gutter:stable]">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
-   <.live_title suffix=" · Phoenix Framework"> 
-     <%= assigns[:page_title] || "Momentum" %>
-   </.live_title>
+   <.inertia_title>Momentum</.inertia_title>
+   <.inertia_head content={@inertia_head} />
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
    </script>
  </head>
  <body class="bg-white antialiased">
    <%= @inner_content %>
  </body>
</html>
```

Now we can change our `PageController` to `render_inertia`

```elixir
# lib/momentum_web/controllers/page_controller.ex
defmodule MomentumWeb.PageController do
  use MomentumWeb, :controller

  def home(conn, _params) do
    render_inertia(conn, "HomePage") # <-- Change this line
  end
end
```

### Changes to JavaScript Frontend

Now we that we have updated our Phoenix server, we need to update our JavaScript frontend.

First, we need to install our frontend dependencies.
```bash
npm install --prefix assets react react-dom @inertiajs/react
```

Next, I like to modify the projects `setup` script to including installing npm dependencies.
```elixir
# mix.exs
defp aliases do
    [
      setup: # ... unchanged
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd npm install --prefix assets" # <-- Add this line
      ],
      "assets.build": # ...unchanged
      "assets.deploy": # ...unchanged
    ]
  end
```

Now we need to rename our `assets/js/app.js` file to `assets/js/app.tsx`, and then add the Inertia intialization code.
```tsx
// assets/js/app.tsx
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { createInertiaApp } from "@inertiajs/react"; // <-- Add this line
import { createRoot } from "react-dom/client"; // <-- Add this line
import pages from "./pages"; // <-- Add this line

// The rest of the the app.js file is unchanged, until the end where we add:
createInertiaApp({
  resolve: (name) => {
    return pages[name as keyof typeof pages];
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />);
  },
});
```

_NB: There are other changes to the app.tsx file made for the sake of quieting the typescript checker. See the git diff for more details since they don't directly relate to inertia._


We should also add a `tsconfig.json` file to the `assets` directory.
```json
// assets/tsconfig.json
{
  "compilerOptions": {
    /* Base Options: */
    "esModuleInterop": true,
    "skipLibCheck": true,
    "target": "es2022",
    "allowJs": true,
    "resolveJsonModule": true,
    "moduleDetection": "force",
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    /* Strictness */
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    /* JSX */
    "jsx": "react-jsx",
    /* If NOT transpiling with TypeScript: */
    "module": "preserve",
    "noEmit": true,
    /* If your code runs in the DOM: */
    "lib": ["es2022", "dom", "dom.iterable"]
  }
}
```

Now we can add our home page. Crate a file, `assets/js/pages/HomePage.tsx`, and add the following code.

```tsx
// assets/js/pages/HomePage.tsx
export function HomePage() {
  return (
    <div>
      <h1>Home Page</h1>
    </div>
  );
}
```

And rexport in a `assets/js/pages/index.ts` file.
```ts
// assets/js/pages/index.ts
import { HomePage } from "./HomePage";

const pages = {
    HomePage
};

export default pages;
```

Lastly, we need to update our configuration to tell `esbuild` to compile our `app.tsx` file.
We are also going to modify the target to es2022 and set the platform to `browser`.

```elixir
# config/config.exs
config :esbuild,
  version: "0.17.11",
  momentum: [
    args:
      # Modify this line
      ~w(js/app.tsx --bundle --target=es2022 --platform=browser --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

With that we are ready to start the Phoenix server.
`mix phx.server`, navigate to `localhost:4000` and you should see the home page we created in React!
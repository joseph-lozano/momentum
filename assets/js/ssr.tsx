
import ReactDOMServer from "react-dom/server";
import { createInertiaApp } from "@inertiajs/react";
import pages from "./pages";

type Page = Parameters<typeof createInertiaApp>[0]["page"];
export function render(page: Page) {
  return createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      return pages[name as keyof typeof pages];
    },
    setup: ({ App, props }) => <App {...props} />,
  });
}
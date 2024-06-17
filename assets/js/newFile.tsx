import { createInertiaApp } from "@inertiajs/react";
import { hydrateRoot } from "react-dom/client";
import pages from "./pages";

createInertiaApp({
  resolve: (name) => {
    return pages[name as keyof typeof pages];
  },
  setup({ el, App, props }) {
    hydrateRoot(el).render(<App {...props} />);
  },
});

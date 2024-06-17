defmodule MomentumWeb.PageController do
  use MomentumWeb, :controller

  def home(conn, _params) do
    render_inertia(conn, "HomePage")
  end
end

defmodule Membrane.Scissors.Plugin.MixProject do
  use Mix.Project

  @version "0.8.1"
  @github_url "https://github.com/membraneframework/membrane_scissors_plugin"

  def project do
    [
      app: :membrane_scissors_plugin,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Scissors plugin for Membrane Framework",
      package: package(),
      name: "Membrane Scissors plugin",
      source_url: @github_url,
      docs: docs(),
      deps: deps(),
      dialyzer: dialyzer(),
      homepage_url: "https://membrane.stream"
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.Scissors]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling],
      plt_add_apps: [:syntax_tools]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      File.mkdir_p!(Path.join([__DIR__, "priv", "plts"]))
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp deps do
    [
      {:membrane_core, "~> 1.0"},
      {:stream_split, "~> 0.1.3"},
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false}
    ]
  end
end

defmodule ExDoc.Markdown.Pandoc do
  def available? do
    !!System.find_executable("pandoc")
  end

  @doc """
  Pandoc specific options:

    * `:format` - output format, defaults to :html
    * `:header_level` - base header level, outputs to 1

  """
  def to_html(text, opts \\ []) when is_binary(text) do
    text
    |> text_to_file()
    |> open_port(opts)
    |> process_port()
  end

  defp text_to_file(text) do
    id = :crypto.rand_bytes(4) |> Base.encode16
    unique_name = "tmpdoc_#{id}.md"
    tmp_path = Path.join(System.tmp_dir, unique_name)
    File.write!(tmp_path, text)
    tmp_path
  end

  defp open_port(path, opts) do
    exe  = :os.find_executable('pandoc')
    args = ["--from", "markdown",
            "--to", get_string(opts, :format, :html),
            "--base-header-level", get_string(opts, :header_level, 1),
            path]
    Port.open({:spawn_executable, exe}, [:stream, :binary, {:args, args},
              :hide, :use_stdio, :stderr_to_stdout, :exit_status])
  end

  defp get_string(opts, key, default) do
    Keyword.get(opts, key, default) |> to_string
  end

  defp process_port(port) do
    {0, data} = collect_output(port, [])
    data
  end

  defp collect_output(port, data) do
    receive do
      {^port, {:data, new_data}} ->
        collect_output(port, [data, new_data])

      {^port, {:exit_status, status}} ->
        {status, List.to_string(data)}
    end
  end
end

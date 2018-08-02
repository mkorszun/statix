defmodule Statix.Conn do
  @moduledoc false

  defstruct [:sock, :header, :addr, :port, :mode]

  alias Statix.Packet

  def new(host, port, opts \\ [])

  def new(host, port, opts) when is_binary(host) do
    new(string_to_charlist(host), port, opts)
  end

  def new(host, port, opts) when is_list(host) or is_tuple(host) do
    {:ok, addr} = :inet.getaddr(host, :inet)
    mode = Keyword.get(opts, :mode, :udp)
    header = Packet.header(addr, port)
    %__MODULE__{header: header, addr: addr, port: port, mode: mode}
  end

  def open(%__MODULE__{mode: :tcp, addr: addr, port: port} = conn) do
    {:ok, sock} = :gen_tcp.connect(addr, port, [:binary, {:active, false}])
    %__MODULE__{conn | sock: sock}
  end

  def open(%__MODULE__{} = conn) do
    {:ok, sock} = :gen_udp.open(0, [active: false])
    %__MODULE__{conn | sock: sock}
  end

  def transmit(%__MODULE__{} = conn, type, key, val, options)
      when is_binary(val) and is_list(options) do
    Packet.build(conn.header, type, key, val, options)
    |> transmit(conn.sock)
  end

  defp transmit(packet, sock) do
    Port.command(sock, packet)
    receive do
      {:inet_reply, _port, status} -> status
    end
  end
  
  if Version.match?(System.version(), ">= 1.3.0") do
    defp string_to_charlist(string), do: String.to_charlist(string)
  else
    defp string_to_charlist(string), do: String.to_char_list(string)
  end
end

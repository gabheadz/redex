defmodule RedexServerTest do
  use ExUnit.Case

  @test_port 6455
  # doctest Redex.Server

  setup do
    IO.puts "starting server"
    {:ok, server} = Redex.Server.start_link([port: @test_port])
    %{pid: server}
  end

  setup context do
    Redex.TestUtils.wait_for_server("localhost", @test_port)
    :ok
  end

  setup context do
    {:ok, conn} = Redix.start_link(host: "localhost", port: @test_port)
    %{conn: conn}
  end

  test "it starts", %{pid: pid} do
    assert Process.alive?(pid)
  end
end

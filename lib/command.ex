defmodule Redex.Command do
  import Redex.RESPEncoder
  @invalid_command_message "Command invalid or not implemented"


  def execute([command | args]) do
    case command |> String.upcase do
      "COMMAND" -> {:simple_str, "OK"}
      "PING" -> {:simple_str, "PONG"}
      "ECHO" -> {:simple_str, Enum.at(args, 0)}
      "SET" -> set(args)
      "SETEX" -> setex(args)
      "GET" -> get(Enum.at(args, 0))
      "DEL" -> del(args)
      _ -> raise @invalid_command_message
    end
  end

  def encode_response(response) do
    encode(response)
  end

  def set(args) do
    case args do
      [key, value] ->
        Redex.KV.set(key, %{value: value})
      [key, value, time_unit, delta_str] ->
        {delta, _} = Integer.parse(delta_str)
        now = Time.utc_now()
        expires = case time_unit |> String.upcase do
          "EX" -> Time.add(now, delta, :second)
          "PX" -> Time.add(now, delta, :millisecond)
        end
        Redex.KV.set(key, %{value: value, expires: expires})
      _ -> raise @invalid_command_message
    end
    {:simple_str, "OK"}
  end

  def setex(args) do
    case args do
      [key, value] ->
        Redex.KV.set(key, %{value: value})
      [key, delta_str, value] ->
        {delta, _} = Integer.parse(delta_str)
        now = Time.utc_now()
        expires = Time.add(now, delta, :millisecond)
        Redex.KV.set(key, %{value: value, expires: expires})
      _ -> raise @invalid_command_message
    end
    {:simple_str, "OK"}
  end

  def get(key) do
    value = case Redex.KV.get(key) |> IO.inspect() do
      nil -> nil
      %{value: val, expires: expiry} ->
        now = Time.utc_now()
        if Time.compare(expiry, now) == :gt do
          val
        else
          nil
        end
      %{value: val} -> val
    end
    {:bulk_str, value}
  end

  def del([key]) do
    Redex.KV.delete(key)
    {:simple_str, "OK"}
  end

end

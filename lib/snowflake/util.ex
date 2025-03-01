defmodule Snowflake.Util do
  @moduledoc """
  The Util module helps users work with snowflake IDs.

  Util module can do the following:
  - Deriving timestamp based on ID
  - Creating buckets based on days since epoch...
  - get real timestamp of any ID
  """
  use Bitwise

  @doc """
  Returns the timestamp in millis. Uses `System.os_time/1`.
  """
  @spec ts :: integer
  def ts do
    Snowflake.Helper.epoch()
    |> ts()
  end

  @doc """
  Returns the timestamp in millis from the machine epoch. Uses `System.os_time/1`.
  """
  def ts(epoch) do
    System.os_time(:millisecond) - epoch
  end

  @doc """
  First Snowflake for timestamp, useful if you have a timestamp and want
  to find snowflakes before or after a certain millisecond
  """
  @spec first_snowflake_for_timestamp(Snowflake.unix_timestamp()) :: Snowflake.t()
  def first_snowflake_for_timestamp(timestamp) do
    ts = timestamp - Snowflake.Helper.epoch()

    <<new_id::unsigned-integer-size(64)>> = <<
      ts::unsigned-integer-size(42),
      0::unsigned-integer-size(10),
      0::unsigned-integer-size(12)
    >>

    new_id
  end

  @doc """
  Get timestamp in ms from your config epoch from any snowflake ID
  """
  @spec timestamp_of_id(Snowflake.t()) :: Snowflake.epoch_timestamp()
  def timestamp_of_id(id) do
    id >>> 22
  end

  @doc """
  Get timestamp from computer epoch - January 1, 1970, Midnight
  """
  @spec real_timestamp_of_id(Snowflake.t()) :: Snowflake.unix_timestamp()
  def real_timestamp_of_id(id) do
    timestamp_of_id(id) + Snowflake.Helper.epoch()
  end

  @doc """
  Get bucket value based on segments of N days
  """
  @spec bucket(integer, atom, Snowflake.t()) :: integer
  def bucket(units, unit_type, id) do
    round(timestamp_of_id(id) / bucket_size(unit_type, units))
  end

  @doc """
  When no id is provided, we generate a bucket for the current time
  """
  @spec bucket(integer, atom) :: integer
  def bucket(units, unit_type) do
    timestamp = System.os_time(:millisecond) - Snowflake.Helper.epoch()
    round(timestamp / bucket_size(unit_type, units))
  end

  defp bucket_size(unit_type, units) do
    case unit_type do
      :hours -> 1000 * 60 * 60 * units
      # days is default
      _ -> 1000 * 60 * 60 * 24 * units
    end
  end
end

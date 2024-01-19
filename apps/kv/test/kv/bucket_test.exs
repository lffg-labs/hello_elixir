defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  test "stores values by key" do
    {:ok, b} = KV.Bucket.start_link()
    assert KV.Bucket.get(b, "key:1") == nil

    KV.Bucket.put(b, "key:1", "value 1")
    assert KV.Bucket.get(b, "key:1") == "value 1"
  end
end

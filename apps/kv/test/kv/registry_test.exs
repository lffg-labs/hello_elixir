defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
  end

  test "spawn buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "bucket:1") == :error

    KV.Registry.create(registry, "bucket:1")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "bucket:1")

    KV.Bucket.put(bucket, "key:1", "value 1")
    assert KV.Bucket.get(bucket, "key:1") == "value 1"
  end

  test "doesn't spawn two buckets for the same name", %{registry: registry} do
    KV.Registry.create(registry, "bucket:1")
    {:ok, bucket} = KV.Registry.lookup(registry, "bucket:1")

    KV.Registry.create(registry, "bucket:1")
    assert {:ok, ^bucket} = KV.Registry.lookup(registry, "bucket:1")
  end
end

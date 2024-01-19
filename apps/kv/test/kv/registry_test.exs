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

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "bucket:1")
    {:ok, bucket} = KV.Registry.lookup(registry, "bucket:1")

    Agent.stop(bucket)
    assert :error = KV.Registry.lookup(registry, "bucket:1")
  end

  # This is a temporary test to show the behavior of the linkage between the
  # registry processes and the buckets it initializes.
  #
  # This behavior is, in fact, undesirable as the failure of a bucket incurs on
  # the failure of the registry itself which, would also led to the exiting of
  # all the bucket processes initialized by it. Even though the registry
  # supervisor would restart it, such failure modes would obviously result in
  # data loss. One would not only lose the data stored by the registry process,
  # but also the data of each individual bucket.
  test "failure of one led to failure of all" do
    original_registry_pid = Process.whereis(KV.Registry)

    KV.Registry.create(KV.Registry, "b1")
    {:ok, b1_pid} = KV.Registry.lookup(KV.Registry, "b1")

    KV.Registry.create(KV.Registry, "b2")
    {:ok, b2_pid} = KV.Registry.lookup(KV.Registry, "b2")

    # Make the first bucket exit in a non-normal way.
    GenServer.stop(b1_pid, :error)

    assert Process.alive?(original_registry_pid) == false
    assert Process.alive?(b1_pid) == false
    assert Process.alive?(b2_pid) == false

    assert original_registry_pid != Process.whereis(KV.Registry)
  end
end

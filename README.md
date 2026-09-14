# rtl_common

Shared RTL primitives. Every core here is a **leaf**: it instantiates nothing
outside its own directory, so depending on this repository never drags in a
further dependency.

It exists to be a submodule. Modules that would otherwise each carry their own
copy of a RAM wrapper or a synchroniser take this instead, so there is one
implementation to fix and one to verify.

| Core | Modules | What it is |
|------|---------|------------|
| `akerlund::memory_ram:1.0.0` | `ram_sp`, `ram_sp_bw`, `ram_sdp`, `ram_sdp2c`, `ram_sdp_bw`, `ram_tdp`, `ram_tdp_bw` | Synchronous RAM wrappers: single-port, simple dual-port (one and two clocks), true dual-port, each with a byte-write-enable variant |
| `akerlund::memory_reg:1.0.0` | `reg_sp_rf` | Single-port register file, for storage too small to be worth a RAM |
| `akerlund::cdc_bit_sync:1.0.0` | `cdc_bit_sync`, `cdc_bit_sync_core` | Multi-flop bit synchroniser for a single-bit clock-domain crossing |

`ram_sdp2c` is the two-clock simple-dual-port variant, which is what an
asynchronous FIFO needs; the rest are single-clock.

## Use

Add it as a submodule and let FuseSoC find the cores:

```sh
git submodule add git@github.com:akerlund/rtl_common.git submodules/rtl_common
```

```yaml
# fusesoc.conf
[main]
cores_root = .
```

Then depend on the VLNV:

```yaml
filesets:
  rtl:
    depend:
      - "akerlund::memory_ram:1.0.0"
      - "akerlund::memory_reg:1.0.0"
```

FuseSoC matches a bare version **exactly**, so a depend on `akerlund::memory_ram:0`
is reported as a missing package rather than satisfied by `1.0.0`.

## Consumers

[`rtl_fifo`](https://github.com/akerlund/rtl_fifo) takes `memory_ram` and
`memory_reg`; [`rtl_afifo`](https://github.com/akerlund/rtl_afifo) reaches all
three through `rtl_fifo`.

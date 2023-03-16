//
//  Video.Duplicates.metal
//  Capture
//
//  Created by Ivan Kh on 28.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void compareRGBAStrict(texture2d<float, access::read> texture1 [[ texture(0) ]],
                              texture2d<float, access::read> texture2 [[ texture(1) ]],
                              device float *result [[ buffer(0) ]],
                              uint2 gid [[ thread_position_in_grid ]])
{
    const float resultFloat= *result;

    if (resultFloat == 5) {
        return;
    }

    float4 colorAtPixel1 = texture1.read(gid);
    float4 colorAtPixel2 = texture2.read(gid);

    if (any(colorAtPixel1 != colorAtPixel2)) {
        *result = 5;
    }
    else if (resultFloat == 0) {
        *result = 3;
    }
}

kernel void compareRGBAApprox(texture2d<float, access::read> texture1 [[ texture(0) ]],
                              texture2d<float, access::read_write> texture2 [[ texture(1) ]],
                              device atomic_uint *result [[ buffer(0) ]],
                              const uint2 positionInGrid [[ thread_position_in_grid ]]/*,
                              const uint positionInThreadGroup [[ thread_position_in_threadgroup ]]*/)
{
    float4 colorAtPixel1 = texture1.read(positionInGrid);
    float4 colorAtPixel2 = texture2.read(positionInGrid);
    uint diffSum = 64 * dot(colorAtPixel1 - colorAtPixel2, float4(1,1,1,1)); // 256 color range / 4 components
    bool notEqual = any(colorAtPixel1 != colorAtPixel2);

    if (notEqual) {
        atomic_fetch_add_explicit(&result[0], 1, memory_order_relaxed);
    }

    if (notEqual && diffSum < 24) {
        uint sum = atomic_load_explicit(&result[1], memory_order_relaxed);

        if (sum + diffSum < 4294967295) {
            atomic_fetch_add_explicit(&result[1], 1, memory_order_relaxed);
            atomic_fetch_add_explicit(&result[2], diffSum, memory_order_relaxed);
        }
        else {
            atomic_fetch_add_explicit(&result[2], 0, memory_order_relaxed);
        }
    }

    if (diffSum > 24) {
        uint sum = atomic_load_explicit(&result[1], memory_order_relaxed);

        if (sum + diffSum < 4294967295) {
            atomic_fetch_add_explicit(&result[3], 1, memory_order_relaxed);
            atomic_fetch_add_explicit(&result[4], diffSum, memory_order_relaxed);
        }
        else {
            atomic_fetch_add_explicit(&result[2], 0, memory_order_relaxed);
        }
    }
}

//
//  Video.Duplicates.metal
//  Capture
//
//  Created by Ivan Kh on 28.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void compareRGBA(texture2d<float, access::read> texture1 [[ texture(0) ]],
                        texture2d<float, access::read> texture2 [[ texture(1) ]],
                        device int *result [[ buffer(0) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    int resultInt = *result;

    if (resultInt == 5) {
        return;
    }

    float4 colorAtPixel1 = texture1.read(gid);
    float4 colorAtPixel2 = texture2.read(gid);

    if (any(colorAtPixel1 != colorAtPixel2)) {
        *result = 5;
    }
    else if (resultInt == 0) {
        *result = 3;
    }
}

kernel void comparePlanar(texture2d<float, access::read> texture1 [[ texture(0) ]],
                          texture2d<float, access::read> texture2 [[ texture(1) ]],
                          device int *result [[ buffer(0) ]],
                          uint2 gid [[ thread_position_in_grid ]])
{
    int resultInt = *result;
    
    if (resultInt == 5) {
        return;
    }
    
    float4 colorAtPixel1 = texture1.read(gid);
    float4 colorAtPixel2 = texture2.read(gid);

    if (any(colorAtPixel1 != colorAtPixel2)) {
        *result = 5;
    }
    else if (resultInt == 0) {
        *result = 3;
    }
}

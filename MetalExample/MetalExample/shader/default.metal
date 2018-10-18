//
//  default.metal
//  MetalExample
//
//  Created by cookie on 2018/10/17.
//  Copyright © 2018 zhubingyi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void doNothing(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    outTexture.write(inColor, gid);
}

kernel void white(texture2d<float, access::write> outTexture [[texture(0)]],
                      uint2 gid [[thread_position_in_grid]])
{
    outTexture.write(float4(1,1,1,1), gid);
}

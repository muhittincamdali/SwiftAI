import os
import re

nn_path = "/Users/muhittincamdali/Desktop/Claude Projects/GitHub/SwiftAI/Sources/SwiftAI/ML/Neural/NeuralNetwork.swift"

with open(nn_path, 'r') as f:
    content = f.read()

# Fix the parameter update logic which was trying to mutate a struct in a let loop
# Old:
# for (idx, var param) in layers[i].parameters.enumerated() {
#     if idx < params.count {
#         for i in 0..<param.data.count {
#             param.data[i] = params[idx].data[i]
#         }
#     }
# }

# Actually, the Layer protocol probably defines parameters as [Tensor<Float>] { get } or similar.
# Let's check the Layer protocol.

layers_path = "/Users/muhittincamdali/Desktop/Claude Projects/GitHub/SwiftAI/Sources/SwiftAI/ML/Neural/Layers.swift"
with open(layers_path, 'r') as f:
    layers_content = f.read()

# I need to find the Layer protocol definition.

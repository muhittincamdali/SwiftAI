import os
import re

nn_path = "/Users/muhittincamdali/Desktop/Claude Projects/GitHub/SwiftAI/Sources/SwiftAI/ML/Neural/NeuralNetwork.swift"

with open(nn_path, 'r') as f:
    content = f.read()

# 1. Update applyParameters to use layer.updateParameters
new_apply_params = """    private func applyParameters(_ params: [Tensor<Float>]) {
        var idx = 0
        for layer in layers {
            let layerParamsCount = layer.parameters.count
            if idx + layerParamsCount <= params.count {
                let layerParams = Array(params[idx..<(idx + layerParamsCount)])
                layer.updateParameters(layerParams)
            }
            idx += layerParamsCount
        }
    }"""

content = re.sub(r'private func applyParameters\(_ params: \[Tensor<Float>\]\) \{.*?\}', new_apply_params, content, flags=re.DOTALL)

# 2. Update zeroGradients to use layer.zeroGradients
new_zero_grads = """    public func zeroGradients() {
        for layer in layers {
            layer.zeroGradients()
        }
    }"""
content = re.sub(r'public func zeroGradients\(\) \{.*?\}', new_zero_grads, content, flags=re.DOTALL)

# 3. Fix the argmax check in accuracy calculation
content = content.replace('output.argmax() == target.argmax()', 'output.argmax() == target.argmax()') # No change needed if already correct

with open(nn_path, 'w') as f:
    f.write(content)
print("Updated NeuralNetwork.swift to use new Layer methods")

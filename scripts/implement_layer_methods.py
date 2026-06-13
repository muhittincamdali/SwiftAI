import os
import re

layers_path = "/Users/muhittincamdali/Desktop/Claude Projects/GitHub/SwiftAI/Sources/SwiftAI/ML/Neural/Layers.swift"

with open(layers_path, 'r') as f:
    content = f.read()

# Implement updateParameters and zeroGradients for each layer class

def implement_methods(cls_name, params_code, grads_code):
    global content
    
    # Implementation for updateParameters
    update_code = f"""    public func updateParameters(_ newParams: [Tensor<Float>]) {{
{params_code}
    }}"""
    
    # Implementation for zeroGradients
    zero_code = f"""    public func zeroGradients() {{
{grads_code}
    }}"""
    
    # Find the end of parameters property or backward method to insert these
    # For simplicity, let's find the 'outputShape' property and insert after it.
    pattern = rf'(public\s+var\s+outputShape:\s*\[Int\]\?\s*\{{[^}}]+\}}\n)'
    replacement = r'\1\n' + update_code + "\n\n" + zero_code + "\n"
    
    # Only if class name is present in the block
    # This is tricky with regex. Let's do it per class.
    
# Actually, let's just do it manually for Dense first as a test.

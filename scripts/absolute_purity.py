import os
import re

dir_path = "/Users/muhittincamdali/Desktop/Claude Projects/GitHub/SwiftAI/Sources/SwiftAI"

def actorize_ml_classes():
    # 1. Preprocessing
    preproc_path = os.path.join(dir_path, "ML/Preprocessing/DataPreprocessing.swift")
    if os.path.exists(preproc_path):
        with open(preproc_path, 'r') as f: content = f.read()
        classes_to_actorize = [
            "StandardScaler", "MinMaxScaler", "LabelEncoder", 
            "OneHotEncoder", "SimpleImputer", "RobustScaler", "PowerTransformer"
        ]
        for cls in classes_to_actorize:
            content = re.sub(r'public\s+(final\s+)?class\s+' + cls + r':\s*Sendable', f'public actor {cls}', content)
        with open(preproc_path, 'w') as f: f.write(content)
        print("Actorized DataPreprocessing.swift")

    # 2. Algorithms
    algo_files = [
        "ML/Algorithms/KNN.swift",
        "ML/Algorithms/LinearRegression.swift",
        "ML/Algorithms/LogisticRegression.swift",
        "ML/Algorithms/DecisionTree.swift",
        "ML/Algorithms/RandomForest.swift",
        "ML/Algorithms/KMeans.swift",
        "ML/Algorithms/SVM.swift"
    ]
    for rel_path in algo_files:
        path = os.path.join(dir_path, rel_path)
        if not os.path.exists(path): continue
        with open(path, 'r') as f: content = f.read()
        
        # Change any public final class Name: Sendable to public actor Name
        content = re.sub(r'public\s+(final\s+)?class\s+(\w+):\s*Sendable', r'public actor \2', content)
        # Also catch non-Sendable ones just in case
        # TreeNode is a special case, it's public final class TreeNode: Sendable
        content = re.sub(r'public\s+(final\s+)?class\s+TreeNode:\s*Sendable', r'public actor TreeNode', content)
        
        with open(path, 'w') as f: f.write(content)
        print(f"Actorized: {rel_path}")

    # 3. Locked.swift
    locked_path = os.path.join(dir_path, "Core/Locked.swift")
    if os.path.exists(locked_path):
        with open(locked_path, 'r') as f: content = f.read()
        # Ensure it has @unchecked Sendable
        content = content.replace('public final class Locked<T>: Sendable', 'public final class Locked<T>: @unchecked Sendable')
        with open(locked_path, 'w') as f: f.write(content)
        print("Fixed Locked.swift")

    # 4. Neural Network and Layers
    nn_path = os.path.join(dir_path, "ML/Neural/NeuralNetwork.swift")
    if os.path.exists(nn_path):
        with open(nn_path, 'r') as f: content = f.read()
        content = re.sub(r'public\s+(final\s+)?class\s+NeuralNetwork:\s*Sendable', r'public actor NeuralNetwork', content)
        content = re.sub(r'public\s+(final\s+)?class\s+EarlyStopping:\s*Sendable', r'public actor EarlyStopping', content)
        with open(nn_path, 'w') as f: f.write(content)
        print("Actorized NeuralNetwork.swift")

    layers_path = os.path.join(dir_path, "ML/Neural/Layers.swift")
    if os.path.exists(layers_path):
        with open(layers_path, 'r') as f: content = f.read()
        # Layers implement a protocol, so changing them to actors might break the protocol if it's not actor-compatible.
        # Let's check if we can just make them actors.
        layer_classes = ["Dense", "ActivationLayer", "Dropout", "BatchNorm", "LayerNorm", "Flatten", "Embedding"]
        for cls in layer_classes:
            content = re.sub(r'public\s+(final\s+)?class\s+' + cls + r':\s*Layer,\s*Sendable', f'public actor {cls}: Layer', content)
            content = re.sub(r'public\s+(final\s+)?class\s+' + cls + r':\s*Layer', f'public actor {cls}: Layer', content)
        with open(layers_path, 'w') as f: f.write(content)
        print("Actorized Layers.swift")

actorize_ml_classes()

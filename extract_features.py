import re

def extract_features():
    with open('temp_feature_lines.txt', 'r', encoding='utf-8') as f:
        lines = f.readlines()

    features = []
    # Filter out obvious test/mock lines
    skip_keywords = ['throwOnMissingStub', 'returnValueForMissingStub', 'stubbedDecision', 'stubbedResult', 'StubBarcodeService', 'StubLayer', 'MockQuery', 'Fake', 'StubColorClassifier', 'package-lock.json', 'import ', 'export ']
    
    for line in lines:
        if any(skip in line for skip in skip_keywords):
            continue
            
        # Look for the target keywords
        match = re.search(r'(?i)(probable|new feature|experimental|not started|placeholder|stubbed|stub\s|TODO)', line)
        if match:
            # Clean up the line
            clean_line = line.strip()
            # Remove file path if present (e.g. ./docs/file.md: text)
            clean_line = re.sub(r'^\./[^:]+:\s*', '', clean_line)
            # Remove leading slashes/hashes
            clean_line = re.sub(r'^[/#\-\s]+', '', clean_line)
            
            if len(clean_line) > 5 and clean_line not in features:
                features.append(clean_line)

    with open('extracted_features_summary.md', 'w', encoding='utf-8') as out:
        out.write("# Extracted Feature Mentions\n\n")
        for f in features:
            out.write(f"- {f}\n")

if __name__ == '__main__':
    extract_features()

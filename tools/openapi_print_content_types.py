import json

def get_openapi_response_content_types(filepath):
    try:
        # Load the OpenAPI JSON file
        with open(filepath, 'r', encoding='utf-8') as f:
            openapi_data = json.load(f)
    except FileNotFoundError:
        print(f"Error: The file '{filepath}' was not found.")
        return set()
    except json.JSONDecodeError:
        print(f"Error: '{filepath}' is not a valid JSON file.")
        return set()

    content_types = set()
    paths = openapi_data.get("paths", {})

    # Loop through each endpoint path
    for path, path_item in paths.items():
        if not isinstance(path_item, dict):
            continue
            
        # Loop through each HTTP method (get, post, put, delete, etc.)
        for method, operation in path_item.items():
            if not isinstance(operation, dict):
                continue
                
            responses = operation.get("responses", {})
            
            # Loop through each status code response (200, 400, default, etc.)
            for status, response_obj in responses.items():
                if not isinstance(response_obj, dict):
                    continue
                    
                # Look for the 'content' map which holds media types
                content_map = response_obj.get("content", {})
                if isinstance(content_map, dict):
                    for content_type in content_map.keys():
                        content_types.add(content_type)
                        
    return content_types

# --- Usage Example ---
# Replace 'openapi.json' with the path to your file
openapi_file = 'openapi.json' 
unique_types = get_openapi_response_content_types(openapi_file)

if unique_types:
    print("Available Response Content-Types:")
    for c_type in sorted(unique_types):
        print(f" - {c_type}")
else:
    print("No response content-types found or file failed to load.")

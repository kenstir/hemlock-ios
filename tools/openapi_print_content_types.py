import json

def get_openapi_response_content_types(filepath):
    # Load the OpenAPI JSON file
    with open(filepath, 'r', encoding='utf-8') as f:
        openapi_data = json.load(f)

    #content_types = set()
    content_types_by_status_code = {}
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
                        if not status in content_types_by_status_code:
                            content_types_by_status_code[status] = set()
                        content_types_by_status_code[status].add(content_type)

    return content_types_by_status_code


openapi_file = 'openapi.json' 
m = get_openapi_response_content_types(openapi_file)
for status in sorted(m):
    print(f"{status}")
    unique_types = m[status]
    for c_type in sorted(unique_types):
        print(f" - {c_type}")

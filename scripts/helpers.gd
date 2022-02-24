class_name Helpers


static func get_all_nodes_within(n: Node) -> Array:
	
	var result = []
	for node in n.get_children():
		result.append(node)
		if node.get_child_count() > 0:
			result.append_array(get_all_nodes_within(node))
	return result

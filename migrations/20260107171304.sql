-- Table for storing undirected graph edges (links can be added or removed)
CREATE TABLE routines_graph_edges (
	edge_id      INTEGER PRIMARY KEY,         -- unique identifier for the edge
	node_a_id    INTEGER NOT NULL,            -- identifier of one endpoint
	node_b_id    INTEGER NOT NULL,            -- identifier of the other endpoint
	created_at   TEXT    NOT NULL,            -- timestamp when the edge was added
	deleted_at   TEXT                         -- timestamp when the edge was removed (NULL = still active)
);

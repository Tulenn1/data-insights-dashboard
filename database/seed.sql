-- Datos de ejemplo para desarrollo

INSERT INTO categories (name) VALUES
    ('Electrónica'), ('Ropa'), ('Hogar'), ('Deportes');

INSERT INTO products (name, category_id, price, cost) VALUES
    ('Laptop Pro', 1, 1500.00, 1100.00),
    ('Mouse Inalámbrico', 1, 45.00, 25.00),
    ('Teclado Mecánico', 1, 120.00, 70.00),
    ('Camiseta Algodón', 2, 35.00, 15.00),
    ('Jeans Clásicos', 2, 65.00, 35.00),
    ('Lámpara LED', 3, 55.00, 30.00),
    ('Silla Oficina', 3, 250.00, 160.00),
    ('Pelota Fútbol', 4, 40.00, 20.00),
    ('Raqueta Tenis', 4, 90.00, 55.00);

INSERT INTO customers (name, email, region) VALUES
    ('Juan Pérez', 'juan@email.com', 'Norte'),
    ('María García', 'maria@email.com', 'Sur'),
    ('Carlos López', 'carlos@email.com', 'Centro'),
    ('Ana Torres', 'ana@email.com', 'Norte'),
    ('Luis Martínez', 'luis@email.com', 'Sur');

INSERT INTO orders (customer_id, order_date, total, status) VALUES
    (1, '2024-01-15', 1500.00, 'completed'),
    (2, '2024-02-20', 100.00, 'completed'),
    (3, '2024-03-10', 250.00, 'completed'),
    (1, '2024-04-05', 165.00, 'completed'),
    (4, '2024-05-12', 55.00, 'pending'),
    (5, '2024-06-01', 130.00, 'completed');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 1500.00),
    (2, 2, 1, 45.00),
    (2, 3, 1, 55.00),
    (3, 7, 1, 250.00),
    (4, 4, 2, 35.00),
    (4, 2, 1, 45.00),
    (4, 5, 1, 65.00),
    (5, 6, 1, 55.00),
    (6, 8, 1, 40.00),
    (6, 9, 1, 90.00);

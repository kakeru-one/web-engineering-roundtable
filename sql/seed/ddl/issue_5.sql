-- https://github.com/ochi-sho-private-study/mysql-sandbox/issues/5

-- prefecturesテーブルの作成
CREATE TABLE prefectures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- employee_rostersテーブルの作成
CREATE TABLE employee_rosters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    prefecture_id INT,
    age INT,
    FOREIGN KEY (prefecture_id) REFERENCES prefectures(id)
);

-- sales_logsテーブルの作成
CREATE TABLE sales_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_roster_id INT,
    sales_quantity INT,
    sales_date DATE,
    FOREIGN KEY (employee_roster_id) REFERENCES employee_rosters(id)
);

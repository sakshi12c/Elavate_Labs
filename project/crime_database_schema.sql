-- =====================================================
-- CRIME RECORD & INVESTIGATION DATABASE
-- PostgreSQL Schema with Indexes, Views, and Triggers
-- =====================================================

-- 1. DROP EXISTING TABLES (for clean setup)
DROP TABLE IF EXISTS evidence_chain CASCADE;
DROP TABLE IF EXISTS evidence CASCADE;
DROP TABLE IF EXISTS case_officers CASCADE;
DROP TABLE IF EXISTS suspects CASCADE;
DROP TABLE IF EXISTS cases CASCADE;
DROP TABLE IF EXISTS officers CASCADE;

-- 2. CREATE TABLES

-- Officers Table
CREATE TABLE officers (
    officer_id SERIAL PRIMARY KEY,
    badge_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    rank VARCHAR(30),
    department VARCHAR(50),
    contact_number VARCHAR(15),
    email VARCHAR(100),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Suspended'))
);

-- Cases Table
CREATE TABLE cases (
    case_id SERIAL PRIMARY KEY,
    case_number VARCHAR(30) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    crime_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
    location VARCHAR(200),
    incident_date TIMESTAMP,
    reported_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(30) DEFAULT 'Open' CHECK (status IN ('Open', 'Under Investigation', 'Solved', 'Cold Case', 'Closed')),
    lead_officer_id INTEGER REFERENCES officers(officer_id),
    closed_date TIMESTAMP,
    notes TEXT
);

-- Suspects Table
CREATE TABLE suspects (
    suspect_id SERIAL PRIMARY KEY,
    case_id INTEGER REFERENCES cases(case_id) ON DELETE CASCADE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    alias VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(10),
    physical_description TEXT,
    address VARCHAR(200),
    contact_number VARCHAR(15),
    criminal_history TEXT,
    arrest_status VARCHAR(30) DEFAULT 'At Large' CHECK (arrest_status IN ('At Large', 'Detained', 'Arrested', 'Released', 'Convicted')),
    arrest_date TIMESTAMP,
    notes TEXT
);

-- Evidence Table
CREATE TABLE evidence (
    evidence_id SERIAL PRIMARY KEY,
    case_id INTEGER REFERENCES cases(case_id) ON DELETE CASCADE,
    evidence_number VARCHAR(30) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    evidence_type VARCHAR(50),
    collection_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    collection_location VARCHAR(200),
    collected_by INTEGER REFERENCES officers(officer_id),
    storage_location VARCHAR(100),
    status VARCHAR(30) DEFAULT 'Collected' CHECK (status IN ('Collected', 'In Analysis', 'Processed', 'Returned', 'Destroyed')),
    chain_of_custody_maintained BOOLEAN DEFAULT true
);

-- Case Officers Assignment (Many-to-Many relationship)
CREATE TABLE case_officers (
    assignment_id SERIAL PRIMARY KEY,
    case_id INTEGER REFERENCES cases(case_id) ON DELETE CASCADE,
    officer_id INTEGER REFERENCES officers(officer_id) ON DELETE CASCADE,
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role VARCHAR(50) DEFAULT 'Investigator',
    is_active BOOLEAN DEFAULT true,
    UNIQUE(case_id, officer_id)
);

-- Evidence Chain of Custody Log
CREATE TABLE evidence_chain (
    chain_id SERIAL PRIMARY KEY,
    evidence_id INTEGER REFERENCES evidence(evidence_id) ON DELETE CASCADE,
    handler_officer_id INTEGER REFERENCES officers(officer_id),
    action VARCHAR(50) NOT NULL,
    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location VARCHAR(200),
    purpose TEXT,
    notes TEXT
);

-- 3. CREATE INDEXES for Performance

-- Index on case_id for fast lookups
CREATE INDEX idx_cases_case_id ON cases(case_id);
CREATE INDEX idx_cases_case_number ON cases(case_number);
CREATE INDEX idx_cases_status ON cases(status);
CREATE INDEX idx_cases_crime_type ON cases(crime_type);
CREATE INDEX idx_cases_incident_date ON cases(incident_date);

-- Index on suspect names for fast searching
CREATE INDEX idx_suspects_last_name ON suspects(last_name);
CREATE INDEX idx_suspects_first_name ON suspects(first_name);
CREATE INDEX idx_suspects_case_id ON suspects(case_id);
CREATE INDEX idx_suspects_arrest_status ON suspects(arrest_status);

-- Index on officer assignments
CREATE INDEX idx_case_officers_case_id ON case_officers(case_id);
CREATE INDEX idx_case_officers_officer_id ON case_officers(officer_id);

-- Index on evidence
CREATE INDEX idx_evidence_case_id ON evidence(case_id);
CREATE INDEX idx_evidence_number ON evidence(evidence_number);

-- 4. CREATE VIEWS

-- View: Officer Workload
CREATE OR REPLACE VIEW officer_workload AS
SELECT 
    o.officer_id,
    o.badge_number,
    o.first_name || ' ' || o.last_name AS officer_name,
    o.rank,
    o.department,
    COUNT(DISTINCT co.case_id) AS total_cases,
    COUNT(DISTINCT CASE WHEN c.status IN ('Open', 'Under Investigation') THEN co.case_id END) AS active_cases,
    COUNT(DISTINCT CASE WHEN c.status = 'Solved' THEN co.case_id END) AS solved_cases,
    COUNT(DISTINCT CASE WHEN c.status = 'Cold Case' THEN co.case_id END) AS cold_cases,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN c.status = 'Solved' THEN co.case_id END) / 
        NULLIF(COUNT(DISTINCT co.case_id), 0), 2
    ) AS solve_rate_percentage
FROM 
    officers o
LEFT JOIN 
    case_officers co ON o.officer_id = co.officer_id AND co.is_active = true
LEFT JOIN 
    cases c ON co.case_id = c.case_id
WHERE 
    o.status = 'Active'
GROUP BY 
    o.officer_id, o.badge_number, o.first_name, o.last_name, o.rank, o.department
ORDER BY 
    active_cases DESC, total_cases DESC;

-- View: Case Summary Report
CREATE OR REPLACE VIEW case_summary_report AS
SELECT 
    c.case_id,
    c.case_number,
    c.title,
    c.crime_type,
    c.severity,
    c.status,
    c.incident_date,
    c.reported_date,
    o.first_name || ' ' || o.last_name AS lead_officer,
    COUNT(DISTINCT s.suspect_id) AS suspect_count,
    COUNT(DISTINCT e.evidence_id) AS evidence_count,
    COUNT(DISTINCT co.officer_id) AS assigned_officers,
    CASE 
        WHEN c.closed_date IS NOT NULL THEN 
            EXTRACT(DAY FROM (c.closed_date - c.reported_date))
        ELSE 
            EXTRACT(DAY FROM (CURRENT_TIMESTAMP - c.reported_date))
    END AS days_open
FROM 
    cases c
LEFT JOIN 
    officers o ON c.lead_officer_id = o.officer_id
LEFT JOIN 
    suspects s ON c.case_id = s.case_id
LEFT JOIN 
    evidence e ON c.case_id = e.case_id
LEFT JOIN 
    case_officers co ON c.case_id = co.case_id AND co.is_active = true
GROUP BY 
    c.case_id, c.case_number, c.title, c.crime_type, c.severity, 
    c.status, c.incident_date, c.reported_date, c.closed_date,
    o.first_name, o.last_name;

-- View: Unsolved Cases Analysis
CREATE OR REPLACE VIEW unsolved_cases_analysis AS
SELECT 
    c.case_id,
    c.case_number,
    c.title,
    c.crime_type,
    c.severity,
    c.incident_date,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - c.reported_date)) AS days_unsolved,
    COUNT(DISTINCT s.suspect_id) AS suspects,
    COUNT(DISTINCT e.evidence_id) AS evidence_items,
    o.first_name || ' ' || o.last_name AS lead_officer
FROM 
    cases c
LEFT JOIN 
    suspects s ON c.case_id = s.case_id
LEFT JOIN 
    evidence e ON c.case_id = e.case_id
LEFT JOIN 
    officers o ON c.lead_officer_id = o.officer_id
WHERE 
    c.status IN ('Open', 'Under Investigation', 'Cold Case')
GROUP BY 
    c.case_id, c.case_number, c.title, c.crime_type, c.severity,
    c.incident_date, c.reported_date, o.first_name, o.last_name
ORDER BY 
    c.severity DESC, days_unsolved DESC;

-- View: Evidence Chain of Custody
CREATE OR REPLACE VIEW evidence_custody_view AS
SELECT 
    e.evidence_id,
    e.evidence_number,
    e.description AS evidence_description,
    c.case_number,
    ec.chain_id,
    ec.action,
    ec.action_date,
    o.first_name || ' ' || o.last_name AS handler,
    ec.location,
    ec.purpose,
    e.chain_of_custody_maintained
FROM 
    evidence e
INNER JOIN 
    cases c ON e.case_id = c.case_id
LEFT JOIN 
    evidence_chain ec ON e.evidence_id = ec.evidence_id
LEFT JOIN 
    officers o ON ec.handler_officer_id = o.officer_id
ORDER BY 
    e.evidence_id, ec.action_date DESC;

-- 5. CREATE TRIGGERS

-- Trigger Function: Automatically log evidence chain updates
CREATE OR REPLACE FUNCTION log_evidence_chain()
RETURNS TRIGGER AS $$
BEGIN
    -- Log any status change to evidence
    IF (TG_OP = 'UPDATE' AND OLD.status != NEW.status) THEN
        INSERT INTO evidence_chain (
            evidence_id, 
            handler_officer_id, 
            action, 
            action_date, 
            location, 
            purpose
        ) VALUES (
            NEW.evidence_id,
            NEW.collected_by,
            'Status changed to: ' || NEW.status,
            CURRENT_TIMESTAMP,
            NEW.storage_location,
            'Automatic status update trigger'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to evidence table
CREATE TRIGGER evidence_chain_update
AFTER UPDATE ON evidence
FOR EACH ROW
EXECUTE FUNCTION log_evidence_chain();

-- Trigger Function: Update case status when all suspects are convicted
CREATE OR REPLACE FUNCTION update_case_status()
RETURNS TRIGGER AS $$
DECLARE
    total_suspects INTEGER;
    convicted_suspects INTEGER;
BEGIN
    -- Count total and convicted suspects for the case
    SELECT COUNT(*), COUNT(CASE WHEN arrest_status = 'Convicted' THEN 1 END)
    INTO total_suspects, convicted_suspects
    FROM suspects
    WHERE case_id = NEW.case_id;
    
    -- If all suspects are convicted and case is not already solved, mark as solved
    IF total_suspects > 0 AND total_suspects = convicted_suspects THEN
        UPDATE cases
        SET status = 'Solved', closed_date = CURRENT_TIMESTAMP
        WHERE case_id = NEW.case_id AND status != 'Solved';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to suspects table
CREATE TRIGGER check_case_solved
AFTER INSERT OR UPDATE ON suspects
FOR EACH ROW
EXECUTE FUNCTION update_case_status();

-- 6. SAMPLE DATA (Optional - for testing)

-- Insert Officers
INSERT INTO officers (badge_number, first_name, last_name, rank, department, contact_number, email, hire_date) VALUES
('B001', 'John', 'Martinez', 'Detective', 'Homicide', '555-0101', 'j.martinez@pd.gov', '2015-03-15'),
('B002', 'Sarah', 'Chen', 'Sergeant', 'Robbery', '555-0102', 's.chen@pd.gov', '2017-06-20'),
('B003', 'Michael', 'O''Brien', 'Detective', 'Cybercrime', '555-0103', 'm.obrien@pd.gov', '2018-01-10'),
('B004', 'Emily', 'Rodriguez', 'Officer', 'Patrol', '555-0104', 'e.rodriguez@pd.gov', '2020-09-05');

-- Insert Cases
INSERT INTO cases (case_number, title, description, crime_type, severity, location, incident_date, status, lead_officer_id) VALUES
('2024-H-001', 'Downtown Robbery', 'Armed robbery at convenience store', 'Robbery', 'High', '123 Main St', '2024-01-15 22:30:00', 'Under Investigation', 2),
('2024-H-002', 'Vehicle Theft Ring', 'Organized vehicle theft operation', 'Theft', 'Medium', 'Various locations', '2024-02-01 14:00:00', 'Open', 1),
('2024-C-001', 'Corporate Data Breach', 'Unauthorized access to company database', 'Cybercrime', 'Critical', 'Tech Corp HQ', '2024-03-10 09:00:00', 'Solved', 3);

-- Insert Suspects
INSERT INTO suspects (case_id, first_name, last_name, alias, date_of_birth, gender, arrest_status) VALUES
(1, 'James', 'Wilson', 'Jimmy', '1985-05-20', 'Male', 'Arrested'),
(2, 'Maria', 'Garcia', NULL, '1990-11-12', 'Female', 'At Large'),
(3, 'Alex', 'Turner', 'A.T.', '1992-08-03', 'Male', 'Convicted');

-- Insert Evidence
INSERT INTO evidence (case_id, evidence_number, description, evidence_type, collection_location, collected_by, storage_location) VALUES
(1, 'EV-2024-001', 'Security camera footage', 'Digital', '123 Main St', 2, 'Digital Archive Room 3'),
(1, 'EV-2024-002', 'Fingerprints from counter', 'Physical', '123 Main St', 2, 'Evidence Locker B-12'),
(3, 'EV-2024-010', 'Server logs and IP addresses', 'Digital', 'Tech Corp HQ', 3, 'Cybercrime Lab - Server A');

-- Assign Officers to Cases
INSERT INTO case_officers (case_id, officer_id, role) VALUES
(1, 2, 'Lead Investigator'),
(1, 4, 'Support Officer'),
(2, 1, 'Lead Investigator'),
(3, 3, 'Lead Investigator');

-- Insert initial evidence chain entries
INSERT INTO evidence_chain (evidence_id, handler_officer_id, action, location, purpose) VALUES
(1, 2, 'Collected', '123 Main St', 'Initial collection from crime scene'),
(1, 2, 'Transferred', 'Digital Archive Room 3', 'Moved to secure storage'),
(2, 2, 'Collected', '123 Main St', 'Collected fingerprint samples'),
(2, 2, 'Transferred', 'Evidence Locker B-12', 'Secured in evidence locker');


COMMENT ON TABLE cases IS 'Stores all criminal cases and investigations';
COMMENT ON TABLE suspects IS 'Stores information about suspects linked to cases';
COMMENT ON TABLE officers IS 'Police officers and investigators';
COMMENT ON TABLE evidence IS 'Physical and digital evidence collected for cases';
COMMENT ON VIEW officer_workload IS 'Shows workload distribution across officers';
COMMENT ON VIEW unsolved_cases_analysis IS 'Analysis of open and unsolved cases';
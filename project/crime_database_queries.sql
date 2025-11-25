-- =====================================================
-- CRIME DATABASE - QUERIES AND REPORTS
-- =====================================================

-- =====================================================
-- 1. CASE ANALYSIS QUERIES
-- =====================================================

-- 1.1 Solved vs Unsolved Cases with Statistics
SELECT 
    status,
    COUNT(*) AS case_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    COUNT(CASE WHEN severity = 'Critical' THEN 1 END) AS critical_cases,
    COUNT(CASE WHEN severity = 'High' THEN 1 END) AS high_priority_cases
FROM cases
GROUP BY status
ORDER BY case_count DESC;

-- 1.2 Cases by Crime Type
SELECT 
    crime_type,
    COUNT(*) AS total_cases,
    COUNT(CASE WHEN status = 'Solved' THEN 1 END) AS solved,
    COUNT(CASE WHEN status IN ('Open', 'Under Investigation') THEN 1 END) AS active,
    ROUND(100.0 * COUNT(CASE WHEN status = 'Solved' THEN 1 END) / COUNT(*), 2) AS solve_rate
FROM cases
GROUP BY crime_type
ORDER BY total_cases DESC;

-- 1.3 Cases requiring immediate attention (High priority, unsolved)
SELECT 
    c.case_number,
    c.title,
    c.crime_type,
    c.severity,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - c.reported_date)) AS days_open,
    o.first_name || ' ' || o.last_name AS lead_officer,
    COUNT(DISTINCT co.officer_id) AS assigned_officers,
    COUNT(DISTINCT s.suspect_id) AS suspects,
    COUNT(DISTINCT e.evidence_id) AS evidence_items
FROM cases c
LEFT JOIN officers o ON c.lead_officer_id = o.officer_id
LEFT JOIN case_officers co ON c.case_id = co.case_id AND co.is_active = true
LEFT JOIN suspects s ON c.case_id = s.case_id
LEFT JOIN evidence e ON c.case_id = e.case_id
WHERE c.status IN ('Open', 'Under Investigation')
    AND c.severity IN ('High', 'Critical')
GROUP BY c.case_id, c.case_number, c.title, c.crime_type, c.severity, c.reported_date, o.first_name, o.last_name
ORDER BY c.severity DESC, days_open DESC;

-- 1.4 Cold Cases Report
SELECT 
    c.case_number,
    c.title,
    c.crime_type,
    c.incident_date,
    EXTRACT(YEAR FROM AGE(CURRENT_TIMESTAMP, c.reported_date)) AS years_unsolved,
    COUNT(DISTINCT s.suspect_id) AS suspects,
    COUNT(DISTINCT e.evidence_id) AS evidence_items,
    o.first_name || ' ' || o.last_name AS original_lead_officer
FROM cases c
LEFT JOIN suspects s ON c.case_id = s.case_id
LEFT JOIN evidence e ON c.case_id = e.case_id
LEFT JOIN officers o ON c.lead_officer_id = o.officer_id
WHERE c.status = 'Cold Case'
GROUP BY c.case_id, c.case_number, c.title, c.crime_type, c.incident_date, c.reported_date, o.first_name, o.last_name
ORDER BY years_unsolved DESC;

-- 1.5 Monthly Case Trends
SELECT 
    TO_CHAR(reported_date, 'YYYY-MM') AS month,
    COUNT(*) AS cases_reported,
    COUNT(CASE WHEN status = 'Solved' THEN 1 END) AS cases_solved,
    COUNT(CASE WHEN severity IN ('High', 'Critical') THEN 1 END) AS high_priority
FROM cases
WHERE reported_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY TO_CHAR(reported_date, 'YYYY-MM')
ORDER BY month DESC;

-- =====================================================
-- 2. SUSPECT ANALYSIS QUERIES
-- =====================================================

-- 2.1 Search Suspects by Name (Example: searching for "Wilson")
SELECT 
    s.suspect_id,
    s.first_name || ' ' || s.last_name AS suspect_name,
    s.alias,
    s.date_of_birth,
    AGE(CURRENT_DATE, s.date_of_birth) AS age,
    s.arrest_status,
    c.case_number,
    c.title AS case_title,
    c.crime_type,
    c.status AS case_status
FROM suspects s
INNER JOIN cases c ON s.case_id = c.case_id
WHERE s.last_name ILIKE '%Wilson%' OR s.first_name ILIKE '%Wilson%' OR s.alias ILIKE '%Wilson%'
ORDER BY s.last_name, s.first_name;

-- 2.2 Suspects At Large
SELECT 
    s.suspect_id,
    s.first_name || ' ' || s.last_name AS suspect_name,
    s.alias,
    s.date_of_birth,
    s.address,
    s.contact_number,
    c.case_number,
    c.crime_type,
    c.severity,
    c.incident_date
FROM suspects s
INNER JOIN cases c ON s.case_id = c.case_id
WHERE s.arrest_status = 'At Large'
ORDER BY c.severity DESC, c.incident_date DESC;

-- 2.3 Repeat Offenders (suspects in multiple cases)
SELECT 
    s.first_name || ' ' || s.last_name AS suspect_name,
    COUNT(DISTINCT s.case_id) AS case_count,
    STRING_AGG(DISTINCT c.crime_type, ', ') AS crime_types,
    MAX(c.incident_date) AS most_recent_incident
FROM suspects s
INNER JOIN cases c ON s.case_id = c.case_id
GROUP BY s.first_name, s.last_name, s.date_of_birth
HAVING COUNT(DISTINCT s.case_id) > 1
ORDER BY case_count DESC;

-- 2.4 Arrest Status Summary
SELECT 
    arrest_status,
    COUNT(*) AS suspect_count,
    COUNT(DISTINCT case_id) AS related_cases
FROM suspects
GROUP BY arrest_status
ORDER BY suspect_count DESC;

-- =====================================================
-- 3. OFFICER WORKLOAD & PERFORMANCE QUERIES
-- =====================================================

-- 3.1 Complete Officer Workload Report (using view)
SELECT * FROM officer_workload
ORDER BY active_cases DESC, solve_rate_percentage DESC;

-- 3.2 Officers with Highest Solve Rates
SELECT 
    o.badge_number,
    o.first_name || ' ' || o.last_name AS officer_name,
    o.rank,
    COUNT(DISTINCT c.case_id) AS total_cases,
    COUNT(DISTINCT CASE WHEN c.status = 'Solved' THEN c.case_id END) AS solved_cases,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c.status = 'Solved' THEN c.case_id END) / 
          NULLIF(COUNT(DISTINCT c.case_id), 0), 2) AS solve_rate
FROM officers o
INNER JOIN case_officers co ON o.officer_id = co.officer_id
INNER JOIN cases c ON co.case_id = c.case_id
WHERE o.status = 'Active'
GROUP BY o.officer_id, o.badge_number, o.first_name, o.last_name, o.rank
HAVING COUNT(DISTINCT c.case_id) >= 3
ORDER BY solve_rate DESC, solved_cases DESC;

-- 3.3 Officer Case Assignment Details
SELECT 
    o.badge_number,
    o.first_name || ' ' || o.last_name AS officer_name,
    c.case_number,
    c.title,
    c.crime_type,
    c.status,
    co.role,
    co.assigned_date,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - co.assigned_date)) AS days_assigned
FROM officers o
INNER JOIN case_officers co ON o.officer_id = co.officer_id
INNER JOIN cases c ON co.case_id = c.case_id
WHERE co.is_active = true
ORDER BY o.last_name, o.first_name, co.assigned_date DESC;

-- 3.4 Officers Overdue for Workload Balancing
SELECT 
    officer_name,
    active_cases,
    total_cases,
    solve_rate_percentage
FROM officer_workload
WHERE active_cases > (SELECT AVG(active_cases) * 1.5 FROM officer_workload)
ORDER BY active_cases DESC;

-- =====================================================
-- 4. EVIDENCE MANAGEMENT QUERIES
-- =====================================================

-- 4.1 Evidence Summary by Case
SELECT 
    c.case_number,
    c.title,
    c.status AS case_status,
    COUNT(e.evidence_id) AS total_evidence,
    COUNT(CASE WHEN e.status = 'Collected' THEN 1 END) AS collected,
    COUNT(CASE WHEN e.status = 'In Analysis' THEN 1 END) AS in_analysis,
    COUNT(CASE WHEN e.status = 'Processed' THEN 1 END) AS processed,
    COUNT(CASE WHEN e.chain_of_custody_maintained = false THEN 1 END) AS custody_issues
FROM cases c
LEFT JOIN evidence e ON c.case_id = e.case_id
GROUP BY c.case_id, c.case_number, c.title, c.status
ORDER BY total_evidence DESC;

-- 4.2 Evidence Chain of Custody Report
SELECT 
    e.evidence_number,
    e.description,
    c.case_number,
    ec.action,
    ec.action_date,
    o.badge_number,
    o.first_name || ' ' || o.last_name AS handler,
    ec.location,
    ec.purpose
FROM evidence e
INNER JOIN cases c ON e.case_id = c.case_id
LEFT JOIN evidence_chain ec ON e.evidence_id = ec.evidence_id
LEFT JOIN officers o ON ec.handler_officer_id = o.officer_id
WHERE e.evidence_number = 'EV-2024-001'  -- Replace with specific evidence number
ORDER BY ec.action_date;

-- 4.3 Evidence with Custody Issues
SELECT 
    e.evidence_number,
    e.description,
    c.case_number,
    c.title,
    e.status,
    e.storage_location,
    o.first_name || ' ' || o.last_name AS collected_by
FROM evidence e
INNER JOIN cases c ON e.case_id = c.case_id
LEFT JOIN officers o ON e.collected_by = o.officer_id
WHERE e.chain_of_custody_maintained = false
ORDER BY c.severity DESC, e.collection_date;

-- 4.4 Evidence Pending Analysis
SELECT 
    e.evidence_number,
    e.description,
    e.evidence_type,
    c.case_number,
    c.crime_type,
    c.severity,
    e.collection_date,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - e.collection_date)) AS days_pending
FROM evidence e
INNER JOIN cases c ON e.case_id = c.case_id
WHERE e.status IN ('Collected', 'In Analysis')
ORDER BY c.severity DESC, days_pending DESC;

-- =====================================================
-- 5. INVESTIGATION SUMMARY EXPORTS
-- =====================================================

-- 5.1 Complete Case Summary Report
SELECT * FROM case_summary_report
ORDER BY days_open DESC;

-- 5.2 Active Investigation Summary
SELECT 
    c.case_number,
    c.title,
    c.crime_type,
    c.severity,
    c.status,
    c.incident_date,
    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - c.reported_date)) AS days_active,
    o.first_name || ' ' || o.last_name AS lead_officer,
    STRING_AGG(DISTINCT co.first_name || ' ' || co.last_name, ', ') AS team_members,
    COUNT(DISTINCT s.suspect_id) AS suspect_count,
    COUNT(DISTINCT e.evidence_id) AS evidence_count,
    MAX(s.arrest_status) FILTER (WHERE s.arrest_status IN ('Arrested', 'Convicted')) AS arrest_made
FROM cases c
LEFT JOIN officers o ON c.lead_officer_id = o.officer_id
LEFT JOIN case_officers cao ON c.case_id = cao.case_id AND cao.is_active = true
LEFT JOIN officers co ON cao.officer_id = co.officer_id
LEFT JOIN suspects s ON c.case_id = s.case_id
LEFT JOIN evidence e ON c.case_id = e.case_id
WHERE c.status IN ('Open', 'Under Investigation')
GROUP BY c.case_id, c.case_number, c.title, c.crime_type, c.severity, c.status, c.incident_date, c.reported_date, o.first_name, o.last_name
ORDER BY c.severity DESC, days_active DESC;

-- 5.3 Solved Cases Report (for management review)
SELECT 
    c.case_number,
    c.title,
    c.crime_type,
    c.incident_date,
    c.reported_date,
    c.closed_date,
    EXTRACT(DAY FROM (c.closed_date - c.reported_date)) AS days_to_solve,
    o.first_name || ' ' || o.last_name AS lead_officer,
    COUNT(DISTINCT s.suspect_id) AS suspects,
    COUNT(DISTINCT CASE WHEN s.arrest_status = 'Convicted' THEN s.suspect_id END) AS convictions
FROM cases c
LEFT JOIN officers o ON c.lead_officer_id = o.officer_id
LEFT JOIN suspects s ON c.case_id = s.case_id
WHERE c.status = 'Solved'
    AND c.closed_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY c.case_id, c.case_number, c.title, c.crime_type, c.incident_date, c.reported_date, c.closed_date, o.first_name, o.last_name
ORDER BY c.closed_date DESC;

-- 5.4 Department Performance Dashboard
SELECT 
    o.department,
    COUNT(DISTINCT o.officer_id) AS total_officers,
    COUNT(DISTINCT c.case_id) AS total_cases,
    COUNT(DISTINCT CASE WHEN c.status = 'Solved' THEN c.case_id END) AS solved_cases,
    COUNT(DISTINCT CASE WHEN c.status IN ('Open', 'Under Investigation') THEN c.case_id END) AS active_cases,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN c.status = 'Solved' THEN c.case_id END) / 
          NULLIF(COUNT(DISTINCT c.case_id), 0), 2) AS solve_rate,
    ROUND(AVG(EXTRACT(DAY FROM (COALESCE(c.closed_date, CURRENT_TIMESTAMP) - c.reported_date))), 1) AS avg_days_to_close
FROM officers o
LEFT JOIN case_officers co ON o.officer_id = co.officer_id
LEFT JOIN cases c ON co.case_id = c.case_id
WHERE o.status = 'Active'
GROUP BY o.department
ORDER BY solve_rate DESC, total_cases DESC;

-- =====================================================
-- 6. SPECIALIZED INVESTIGATION QUERIES
-- =====================================================

-- 6.1 Cases with Multiple Suspects
SELECT 
    c.case_number,
    c.title,
    c.crime_type,
    c.status,
    COUNT(s.suspect_id) AS suspect_count,
    STRING_AGG(s.first_name || ' ' || s.last_name || ' (' || s.arrest_status || ')', '; ') AS suspects
FROM cases c
INNER JOIN suspects s ON c.case_id = s.case_id
GROUP BY c.case_id, c.case_number, c.title, c.crime_type, c.status
HAVING COUNT(s.suspect_id) > 1
ORDER BY suspect_count DESC;

-- 6.2 Cases Missing Critical Information
SELECT 
    c.case_number,
    c.title,
    c.status,
    CASE WHEN COUNT(s.suspect_id) = 0 THEN 'No suspects identified' END AS suspect_issue,
    CASE WHEN COUNT(e.evidence_id) = 0 THEN 'No evidence collected' END AS evidence_issue,
    CASE WHEN c.lead_officer_id IS NULL THEN 'No lead officer assigned' END AS officer_issue
FROM cases c
LEFT JOIN suspects s ON c.case_id = s.case_id
LEFT JOIN evidence e ON c.case_id = e.case_id
WHERE c.status IN ('Open', 'Under Investigation')
GROUP BY c.case_id, c.case_number, c.title, c.status, c.lead_officer_id
HAVING COUNT(s.suspect_id) = 0 OR COUNT(e.evidence_id) = 0 OR c.lead_officer_id IS NULL;

-- =====================================================
-- 7. DATA EXPORT QUERIES (CSV-ready format)
-- =====================================================

-- 7.1 Export all cases (CSV format)
COPY (
    SELECT 
        case_number,
        title,
        crime_type,
        severity,
        location,
        incident_date,
        status,
        reported_date,
        closed_date
    FROM cases
    ORDER BY reported_date DESC
) TO '/tmp/cases_export.csv' WITH CSV HEADER;

-- 7.2 Export officer workload (CSV format)
COPY (
    SELECT * FROM officer_workload
) TO '/tmp/officer_workload_export.csv' WITH CSV HEADER;
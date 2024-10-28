# Bank Marketing Analytics dbt Project

This dbt project transforms and analyzes bank marketing campaign data .

### Data Source
The dataset comes from the UCI Machine Learning Repository's [Bank Marketing Dataset](https://archive.ics.uci.edu/ml/datasets/Bank+Marketing). It includes various client attributes, campaign information, and economic indicators.

### Architecture
```
raw_data (source)
    │
    ├── staging_bank_marketing (cleaned data)
    │   │
    │   ├── int_campaign_metrics (intermediate calculations)
    │   │
    │   └── fct_campaign_performance (final metrics)
```

## Setup Instructions

### Prerequisites
- Python 3.9+
- dbt-bigquery
- Google Cloud Platform account with BigQuery access
- GCP Service account with necessary permissions

### Initial Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd bank_marketing_analysis
```

2. **Install dependencies**
```bash
pip install dbt-bigquery
dbt deps
```

3. **Configure BigQuery credentials**
- Create a service account in GCP with
1. **BigQuery Data Editor**

2. **BigQuery Job User**

3. **BigQuery User**
```bash
export DBT_GOOGLE_PROJECT=your-project-id
export DBT_GOOGLE_DATASET=your-dataset
export DBT_GOOGLE_KEYFILE=/path/to/your/keyfile.json
```

4. **Create raw dataset and load data**
```sql
-- In BigQuery console
CREATE SCHEMA IF NOT EXISTS `your-project.bank_marketing`
  OPTIONS (
    description = "Raw data for bank marketing analysis",
    location = "US"
  );

-- Create raw table (see schema below)
CREATE OR REPLACE TABLE `your-project.bank_marketing.raw_bank_marketing`...
```

### Running the Project

1. **Test the connection**
```bash
dbt debug
```

2. **Run the models**
```bash
dbt build  # Runs all models and tests
```

## Project Structure

### Data Models

1. **Source Layer (`raw_bank_marketing`)**
   - Original bank marketing data

2. **Staging Layer (`staging_bank_marketing`)**
   - Cleaned and standardized data
   - Type conversions and null handling
   - Derived fields for analysis

3. **Intermediate Layer (`int_campaign_metrics`)**
   - Aggregated campaign metrics

4. **Mart Layer (`fct_campaign_performance`)**
   - Final KPIs and metrics

### Model Details

#### Source Schema
```yaml
age: INT64                    # Client age
job: STRING                   # Type of job
marital: STRING              # Marital status
education: STRING            # Education level
default: STRING              # Has credit in default?
housing: STRING              # Has housing loan?
loan: STRING                 # Has personal loan?
contact: STRING              # Contact communication type
month: STRING               # Last contact month
duration: INT64              # Last contact duration in seconds
campaign: INT64              # Number of contacts performed
pdays: INT64                 # Days since previous contact
previous: INT64              # Previous campaign contacts
poutcome: STRING            # Previous outcome
emp_var_rate: FLOAT64       # Employment variation rate
cons_price_idx: FLOAT64     # Consumer price index
cons_conf_idx: FLOAT64      # Consumer confidence index
euribor3m: FLOAT64          # Euribor 3 month rate
nr_employed: FLOAT64        # Number of employees
y: STRING                   # Has the client subscribed?
```

#### Key Transformations

1. **Data Cleaning (Staging)**
   - Standardizing categorical variables
   - Handling unknown values
   - Creating derived fields (age_segment, contact_intensity)

2. **Metrics Calculation**
   - Conversion rates by segment
   - Campaign effectiveness metrics
   - Customer segmentation analysis

### Testing Strategy

The project includes various data quality tests:

1. **Schema Tests**
   - Not null validations
   - Accepted value ranges
   - Data type validations

2. **Custom Tests**
   - Positive value checks
   - Date range validations

### CI/CD Pipeline

The project uses GitHub Actions for CI/CD:

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click on "Settings"
   - Select "Secrets and variables" → "Actions"
   - Add DBT_GOOGLE_PROJECT=your-project-id BT_GOOGLE_DATASET=your-dataset DBT_GOOGLE_KEYFILE=/path/to/your/keyfile.json

1. **On Push to Main**
   - Installs dependencies
   - Sets up environment
   - Creates/updates datasets
   - Runs all models and tests

```yaml
# Pipeline steps (.github/workflows/dbt_cicd.yml)
1. Setup environment
2. Install dependencies
3. Setup raw data
4. Run dbt build
```

## Project Conventions

### Naming Conventions
- Models: snake_case
- Source tables: raw_*
- Staging models: staging_*
- Intermediate models: int_*
- Fact tables: fct_*
- Dimension tables: dim_*

### Model Configuration
- Staging: materialized as views
- Intermediate: materialized as views
- Marts: materialized as tables

## Useful Commands

```bash
# Running specific models
dbt run --select staging_bank_marketing

# Testing
dbt test                     # Run all tests

# Documentation
dbt docs generate
dbt docs serve
```

## Data Preprocessing

### CSV Parser

The project includes a parser (`parser.py`) to transform the original bank marketing dataset (`bank-additional-full.csv`) into a format compatible with BigQuery loading. This preprocessing step is necessary because the original dataset uses semicolons (;) as delimiters and has specific formatting that needs to be standardized.

#### Parser Details (`parser.py`)
```python
import csv

def convert_bank_data(input_string):
    """
    Converts the bank marketing dataset from semicolon-delimited to comma-delimited format
    and cleans up the data formatting.

    Args:
        input_string: Raw content of bank-additional-full.csv

    Returns:
        String containing the transformed CSV data
    """
    # Process the header and data rows
    # Replace semicolons with commas
    # Clean up quotation marks
    # ...
```

### Usage Instructions

1. **Download Original Dataset**
   ```bash
   # Download from UCI repository
   wget https://archive.ics.uci.edu/ml/machine-learning-databases/00222/bank-additional.zip
   unzip bank-additional.zip
   ```

2. **Run Parser**
   ```bash
   # Process the file
   python parser.py
   ```
   This will:
   - Read `input.txt` (your renamed bank-additional-full.csv)
   - Convert semicolon delimiters to commas
   - Clean up formatting
   - Output to `output.csv`

3. **Load to BigQuery**
   ```bash
   # Load the processed CSV to BigQuery
   bq load \
     --source_format=CSV \
     --skip_leading_rows=1 \
     your-project:bank_marketing.raw_bank_marketing \
     output.csv
   ```

### Data Transformation
The parser performs the following transformations:
- Converts semicolon (;) delimiters to commas (,)
- Removes unnecessary quotation marks
- Cleans column names (replaces dots with underscores)
- Ensures consistent formatting of values

### Original vs. Processed Format

**Original Format (bank-additional-full.csv)**:
```
"age";"job";"marital";"education";"default";"housing";"loan"...
58;"management";"married";"tertiary";"no";"yes";"no"...
```

**Processed Format (output.csv)**:
```
age,job,marital,education,default,housing,loan...
58,management,married,tertiary,no,yes,no...
```

### Best Practices for Data Loading

1. **Before Running Parser**
   - Backup original data file
   - Verify file encoding (should be UTF-8)
   - Check for any special characters

2. **After Parsing**
   - Validate output CSV format
   - Verify column names match target schema
   - Check sample of transformed data

3. **BigQuery Loading**
   - Use appropriate schema definitions
   - Enable data validation
   - Set appropriate null handling

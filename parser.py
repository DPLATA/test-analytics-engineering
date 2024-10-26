import csv

def convert_bank_data(input_string):
    # Split the input string into lines
    lines = input_string.strip().split('\n')

    # Process the header
    header = lines[0].strip('"').split(';')
    # Clean up header names
    header = [h.strip('"') for h in header]
    # Replace dots with underscores in column names
    header = [h.replace('.', '_') for h in header]

    # Process the data rows
    rows = []
    for line in lines[1:]:
        # Split by semicolon and clean up quotes
        values = line.split(';')
        cleaned_values = [v.strip('"') for v in values]
        rows.append(cleaned_values)

    # Prepare output string
    output_lines = []

    # Add header
    output_lines.append(','.join(header))

    # Add data rows
    for row in rows:
        output_lines.append(','.join(row))

    return '\n'.join(output_lines)


with open('input.txt', 'r') as f:
    input_data = f.read()
    converted_data = convert_bank_data(input_data)

with open('output.csv', 'w') as f:
    f.write(converted_data)

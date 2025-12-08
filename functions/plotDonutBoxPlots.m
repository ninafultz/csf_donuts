function plotDonutBarPlots(filename, col_right, col_left, categories)


   % Read the Excel file
    data = readtable(filename, 'FileType', 'spreadsheet'); % Reads .xlsx file
    
    % Extract columns
    A1_right = data.(col_right);
    A1_left = data.(col_left);

    % Initialize counts
    category_counts = zeros(1, length(categories));

    % Count occurrences for each category (combine A1 right and A1 left)
    for i = 1:length(categories)
        category_counts(i) = sum(strcmp(A1_right, categories{i})) + sum(strcmp(A1_left, categories{i}));
    end

    % Compute percentages
    total_counts = sum(category_counts);
    category_percentages = (category_counts / total_counts) * 100;

    % Create a bar plot
    figure;
    bar(category_percentages);
    
    % Set x-axis labels to category names
    set(gca, 'XTickLabel', categories, 'XTick', 1:length(categories));
    ylim([0 100])
    ylabel('Percentage (%)');
    xlabel('Categories');
    
    % Dynamic title with column names
    title(sprintf('Category Distribution from %s and %s', col_right, col_left));

    grid on;
end
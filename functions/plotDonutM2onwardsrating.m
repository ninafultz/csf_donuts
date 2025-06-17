function plotDonutM2onwardsrating(filename, col_right, col_left, categories);
%% 

    % Read the Excel file
    data = readtable(filename, 'FileType', 'spreadsheet'); % Reads .xlsx file

    % Initialize counts for each category
    category_counts = zeros(1, length(categories));

    % Process each subject
    for i = 1:height(data)
        % Combine right and left columns
        combined_labels = [strsplit(data.(col_right){i}, '; '), strsplit(data.(col_left){i}, '; ')];

        % Count occurrences of each category
        for j = 1:length(categories)
            category_counts(j) = category_counts(j) + sum(strcmp(combined_labels, categories{j}));
        end
    end

    % Compute percentages
    total_counts = sum(category_counts);
    category_percentages = (category_counts / total_counts) * 100;

    % Create a bar plot
    figure;
    bar(category_percentages);
    ylim([0 100])
    % Set x-axis labels to category names
    set(gca, 'XTickLabel', categories, 'XTick', 1:length(categories));
    
    ylabel('Percentage (%)');
    xlabel('Categories');
    
    % Dynamic title with column names
    title('Overall Category Distribution (Combined Right & Left)');

    grid on;
    
      % Print out percentages
    fprintf('\nCategory Percentages:\n');
    for i = 1:length(categories)
        fprintf('%s: %.2f%%\n', categories{i}, category_percentages(i));
    end
end

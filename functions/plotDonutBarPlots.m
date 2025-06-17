
function plotDonutBarPlots(filename, col_right, col_left, categories)
%% 

    % Read the Excel file
    data = readtable(filename, 'FileType', 'spreadsheet'); % Reads .xlsx file

    % Initialize counts for each category
    category_counts = zeros(1, length(categories));

    % Store category data for statistical testing
    category_data = cell(1, length(categories));

    % Process each subject
    for i = 1:height(data)
        % Combine right and left columns
        combined_labels = [strsplit(data.(col_right){i}, '; '), strsplit(data.(col_left){i}, '; ')];

        % Count occurrences of each category
        for j = 1:length(categories)
            count = sum(strcmp(combined_labels, categories{j}));
            category_counts(j) = category_counts(j) + count;
            category_data{j} = [category_data{j}, repmat(j, 1, count)]; % Store category indices
        end
    end

    % Compute percentages
    total_counts = sum(category_counts);
    category_percentages = (category_counts / total_counts) * 100;

    % Print out percentages
    fprintf('\nCategory Percentages:\n');
    for i = 1:length(categories)
        fprintf('%s: %.2f%%\n', categories{i}, category_percentages(i));
    end

    % Convert category data to Kruskal-Wallis format
    values = [];
    group_labels = [];
    for i = 1:length(categories)
        values = [values, category_data{i}]; %#ok<AGROW> % Combine all data points
        group_labels = [group_labels, repmat(i, 1, length(category_data{i}))]; %#ok<AGROW>
    end

    % Perform Kruskal-Wallis test
    if length(unique(group_labels)) > 1  % Ensure multiple groups exist
        p_kw = kruskalwallis(values, group_labels, 'off');

        fprintf('\nKruskal-Wallis Test:\n');
        fprintf('p-value: %.4f\n', p_kw);

        if p_kw < 0.05
            fprintf('Significant difference found (p < 0.05). Performing post-hoc tests...\n');

            % Post-hoc pairwise Wilcoxon tests with Bonferroni correction
            comparisons = nchoosek(1:length(categories), 2);
            num_comparisons = size(comparisons, 1);
            corrected_alpha = 0.05 / num_comparisons; % Bonferroni correction

            for c = 1:num_comparisons
                group1 = category_data{comparisons(c, 1)};
                group2 = category_data{comparisons(c, 2)};

                if ~isempty(group1) && ~isempty(group2)
                    p_wilcoxon = ranksum(group1, group2);
                    fprintf('Comparison %s vs. %s: p = %.4f (Bonferroni-corrected alpha = %.4f)\n', ...
                            categories{comparisons(c, 1)}, categories{comparisons(c, 2)}, p_wilcoxon, corrected_alpha);

                    if p_wilcoxon < corrected_alpha
                        fprintf(' -> Significant difference between %s and %s\n', ...
                                categories{comparisons(c, 1)}, categories{comparisons(c, 2)});
                            fprintf('Wilcoxon p-value: %.2e\n', p_wilcoxon);

                    end
                end
            end
        else
            fprintf('No significant difference found (p >= 0.05).\n');
        end
    else
        fprintf('\nNot enough data for Kruskal-Wallis test (only one category present).\n');
    end

    % Create a bar plot
    figure;
    bar(category_percentages);
    
    % Set x-axis labels to category names
    set(gca, 'XTickLabel', categories, 'XTick', 1:length(categories));
    ylim([0 100]);
    ylabel('Percentage (%)');
    xlabel('Categories');

    % Dynamic title
    title('Overall Category Distribution (Combined Right & Left)');

    grid on;
end

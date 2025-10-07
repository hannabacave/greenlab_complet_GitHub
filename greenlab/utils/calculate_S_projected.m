function S_prime = calculate_S_projected(S)
    % INPUT : 
    %   S : un vecteur de taille 12 contenant les valeurs S_i(j)
    % OUTPUT:
    %   S_prime : la valeur de S'(j) calculée avec les formules données
    
    n_j = length(S); % Détermination de n_j
    
    % Initialisation de S_prime
    S_prime = -inf;

    % Détermination de i_max et i_last
    [~,i_max]=max(S);
    i_last=length(S);


    % Boucle pour calculer la valeur maximale de la somme
    for k = 1:n_j
        sum = 0;
        for i = k:(12+k)
            if i<=i_last
                alpha_i = calculate_alpha(i, i_max, i_last);
                sum = sum + S(i-k+1)*cosd(alpha_i);
            end
        end
        S_prime = max(S_prime, sum);
    end
end

function alpha_i = calculate_alpha(i, i_max, i_last)
    % Cette fonction calcule la valeur de alpha_i en fonction de i, i_max et i_last
    % INPUTS:
    %   i : un entier correspondant à l'indice i de la formule
    %   i_max : une constante définie par l'utilisateur
    %   i_last : une constante définie par l'utilisateur
    % OUTPUT:
    %   alpha_i : la valeur de alpha_i calculée avec la formule donnée
    
    if i >= 1 && i <= i_max
        alpha_i = 10;
    elseif i > i_max && i <= i_last
        alpha_i = 60*((i-i_max)/(i_last-i_max)) + 10;
    else
        error('La valeur de i doit être comprise entre 1 et i_last');
    end
end


   
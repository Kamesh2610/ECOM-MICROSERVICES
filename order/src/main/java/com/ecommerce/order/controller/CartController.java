package com.ecommerce.order.controller;

import com.ecommerce.order.dtos.CartItemRequest;
import com.ecommerce.order.models.CartItem;
import com.ecommerce.order.services.CartService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
@Tag(name = "Cart", description = "Shopping cart operations — add items, remove items and view cart contents. All requests require X-User-ID header.")
@SecurityRequirement(name = "Bearer Authentication")
public class CartController {

    private final CartService cartService;

    @Operation(summary = "Add item to cart",
            description = "Add a product to the user's shopping cart. Pass the user's ID in the X-User-ID header.")
    @ApiResponses({
        @ApiResponse(responseCode = "201", description = "Item added to cart successfully"),
        @ApiResponse(responseCode = "400", description = "Product not found or insufficient stock"),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    @PostMapping
    public ResponseEntity<String> addToCart(
            @Parameter(description = "The authenticated user's ID (MongoDB ObjectId)", example = "664c1f2b3e8e4a001c2d3e4f", required = true)
            @RequestHeader("X-User-ID") String userId,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Product ID and quantity to add",
                    required = true,
                    content = @Content(schema = @Schema(implementation = CartItemRequest.class)))
            @RequestBody CartItemRequest request) {
        if (!cartService.addToCart(userId, request)) {
            return ResponseEntity.badRequest().body("Not able to complete the request");
        }
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @Operation(summary = "Remove item from cart",
            description = "Remove a specific product from the user's cart by product ID")
    @ApiResponses({
        @ApiResponse(responseCode = "204", description = "Item removed from cart"),
        @ApiResponse(responseCode = "404", description = "Item not found in cart"),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    @DeleteMapping("/items/{productId}")
    public ResponseEntity<Void> removeFromCart(
            @Parameter(description = "The authenticated user's ID", example = "664c1f2b3e8e4a001c2d3e4f", required = true)
            @RequestHeader("X-User-ID") String userId,
            @Parameter(description = "Product ID to remove from cart", example = "1", required = true)
            @PathVariable String productId) {
        boolean deleted = cartService.deleteItemFromCart(userId, productId);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @Operation(summary = "Get cart contents",
            description = "Retrieve all items currently in the user's shopping cart")
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "Cart contents",
                content = @Content(array = @ArraySchema(schema = @Schema(implementation = CartItem.class)))),
        @ApiResponse(responseCode = "401", description = "Unauthorized")
    })
    @GetMapping
    public ResponseEntity<List<CartItem>> getCart(
            @Parameter(description = "The authenticated user's ID", example = "664c1f2b3e8e4a001c2d3e4f", required = true)
            @RequestHeader("X-User-ID") String userId) {
        return ResponseEntity.ok(cartService.getCart(userId));
    }
}

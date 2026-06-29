package com.photoalbum.controller;

import com.photoalbum.model.Photo;
import com.photoalbum.service.PhotoService;
import com.photoalbum.telemetry.AppTelemetryService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import jakarta.servlet.http.HttpServletRequest;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Optional;

/**
 * Controller for displaying a single photo in full size
 */
@Controller
@RequestMapping("/detail")
public class DetailController {

    private static final Logger logger = LoggerFactory.getLogger(DetailController.class);

    private final PhotoService photoService;
    private final AppTelemetryService telemetryService;

    public DetailController(PhotoService photoService, AppTelemetryService telemetryService) {
        this.photoService = photoService;
        this.telemetryService = telemetryService;
    }

    /**
     * Handles GET requests to display a photo
     */
    @GetMapping("/{id}")
    public String detail(@PathVariable String id, Model model) {
        if (id == null || id.trim().isEmpty()) {
            return "redirect:/";
        }

        try {
            Optional<Photo> photoOpt = photoService.getPhotoById(id);
            if (!photoOpt.isPresent()) {
                return "redirect:/";
            }

            Photo photo = photoOpt.get();
            model.addAttribute("photo", photo);

            // Find previous and next photos for navigation
            Optional<Photo> previousPhoto = photoService.getPreviousPhoto(photo);
            Optional<Photo> nextPhoto = photoService.getNextPhoto(photo);

            model.addAttribute("previousPhotoId", previousPhoto.isPresent() ? previousPhoto.get().getId() : null);
            model.addAttribute("nextPhotoId", nextPhoto.isPresent() ? nextPhoto.get().getId() : null);

            return "detail";
        } catch (Exception ex) {
            logger.error("Error loading photo with ID {}", id, ex);
            return "redirect:/";
        }
    }

    /**
     * Handles POST requests to delete a photo
     */
    @PostMapping("/{id}/delete")
    public String deletePhoto(@PathVariable String id, RedirectAttributes redirectAttributes, HttpServletRequest request) {
<<<<<<< HEAD
        long deleteStartMs = System.currentTimeMillis();
        String sessionId = request.getSession(false) != null ? request.getSession(false).getId() : "unknown";
        String visitorId = "unknown";
        if (request.getSession(false) != null) {
            Object visitor = request.getSession(false).getAttribute("telemetry.visitorId");
            if (visitor != null && !visitor.toString().isBlank()) {
                visitorId = visitor.toString();
            }
        }
        String fileName = "unknown";

        Optional<Photo> photoBeforeDelete = photoService.getPhotoById(id);
        if (photoBeforeDelete.isPresent()) {
            fileName = photoBeforeDelete.get().getOriginalFileName();
        }

=======
        long start = System.currentTimeMillis();
        String sessionId = request.getSession(true).getId();
        String visitorId = resolveVisitorId(request);
        String fileName = "unknown";

>>>>>>> modernize
        try {
            Optional<Photo> photoOpt = photoService.getPhotoById(id);
            if (photoOpt.isPresent() && photoOpt.get().getOriginalFileName() != null && !photoOpt.get().getOriginalFileName().trim().isEmpty()) {
                fileName = photoOpt.get().getOriginalFileName();
            }

            boolean deleted = photoService.deletePhoto(id);
            if (deleted) {
                logger.info("Photo {} deleted successfully", id);
                redirectAttributes.addFlashAttribute("successMessage", "Photo deleted successfully");
                telemetryService.trackDelete(
                        sessionId,
                        visitorId,
                        id,
                        fileName,
<<<<<<< HEAD
                        System.currentTimeMillis() - deleteStartMs,
=======
                        System.currentTimeMillis() - start,
>>>>>>> modernize
                        true,
                        null);
            } else {
                redirectAttributes.addFlashAttribute("errorMessage", "Photo not found");
                telemetryService.trackDelete(
                        sessionId,
                        visitorId,
                        id,
                        fileName,
<<<<<<< HEAD
                        System.currentTimeMillis() - deleteStartMs,
=======
                        System.currentTimeMillis() - start,
>>>>>>> modernize
                        false,
                        "Photo not found");
            }
        } catch (Exception ex) {
            logger.error("Error deleting photo {}", id, ex);
            redirectAttributes.addFlashAttribute("errorMessage", "Failed to delete photo. Please try again.");
            telemetryService.trackDelete(
                    sessionId,
                    visitorId,
                    id,
                    fileName,
<<<<<<< HEAD
                    System.currentTimeMillis() - deleteStartMs,
=======
                    System.currentTimeMillis() - start,
>>>>>>> modernize
                    false,
                    ex.getMessage());
        }
        return "redirect:/";
    }

    private String resolveVisitorId(HttpServletRequest request) {
        Object visitor = request.getAttribute("telemetry.visitorId");
        if (visitor != null) {
            String value = visitor.toString();
            if (!value.trim().isEmpty()) {
                return value;
            }
        }
        return "unknown";
    }
}